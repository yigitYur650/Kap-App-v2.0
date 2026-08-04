package handler

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"

	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
)

// Request simulates a shopping request in the database.
type Request struct {
	ID          string  `json:"id"`
	GroupID     string  `json:"group_id"`
	RequestedBy string  `json:"requested_by"`
	ItemName    string  `json:"item_name"`
	IsPrivate   bool    `json:"is_private"`
	PrivateTo   *string `json:"private_to,omitempty"`
	Status      string  `json:"status"`
}

// InMemDB manages the simulated state for users, groups, memberships, and requests.
type InMemDB struct {
	mu       sync.RWMutex
	users    map[string]string          // user_id -> display_name
	groups   map[string]GroupRecord     // group_id -> group info
	members  map[string]map[string]bool // group_id -> {user_id -> is_member}
	requests []Request
}

// GroupRecord stores group info including join_code and soft-delete status.
type GroupRecord struct {
	Name     string
	JoinCode string
	Deleted  bool
}

func NewInMemDB() *InMemDB {
	return &InMemDB{
		users:    make(map[string]string),
		groups:   make(map[string]GroupRecord),
		members:  make(map[string]map[string]bool),
		requests: []Request{},
	}
}

// RegisterUser registers a user profile in memory.
func (db *InMemDB) RegisterUser(id, name string) {
	db.mu.Lock()
	defer db.mu.Unlock()
	db.users[id] = name
}

// CreateGroup creates a workspace group and makes the creator a member.
func (db *InMemDB) CreateGroup(id, name, joinCode, creatorID string) error {
	db.mu.Lock()
	defer db.mu.Unlock()
	if _, ok := db.users[creatorID]; !ok {
		return fmt.Errorf("creator user %s does not exist", creatorID)
	}
	if joinCode == "" {
		return fmt.Errorf("join_code cannot be empty")
	}
	// Check for join_code uniqueness among active groups
	for gid, grp := range db.groups {
		if !grp.Deleted && grp.JoinCode == joinCode && gid != id {
			return fmt.Errorf("join_code %s already in use by group %s", joinCode, gid)
		}
	}
	db.groups[id] = GroupRecord{Name: name, JoinCode: joinCode, Deleted: false}
	if db.members[id] == nil {
		db.members[id] = make(map[string]bool)
	}
	db.members[id][creatorID] = true
	return nil
}

// SoftDeleteGroup marks a group as deleted (soft delete).
func (db *InMemDB) SoftDeleteGroup(groupID string) error {
	db.mu.Lock()
	defer db.mu.Unlock()
	grp, ok := db.groups[groupID]
	if !ok {
		return fmt.Errorf("group %s does not exist", groupID)
	}
	grp.Deleted = true
	db.groups[groupID] = grp
	return nil
}

// GetGroupByJoinCode finds an active group by its join code.
func (db *InMemDB) GetGroupByJoinCode(joinCode string) (string, error) {
	db.mu.RLock()
	defer db.mu.RUnlock()
	for gid, grp := range db.groups {
		if !grp.Deleted && grp.JoinCode == joinCode {
			return gid, nil
		}
	}
	return "", fmt.Errorf("no active group found with join_code %s", joinCode)
}

// JoinGroup adds a user to a group as a member.
func (db *InMemDB) JoinGroup(groupID, userID string) error {
	db.mu.Lock()
	defer db.mu.Unlock()
	grp, ok := db.groups[groupID]
	if !ok || grp.Deleted {
		return fmt.Errorf("group %s does not exist or is deleted", groupID)
	}
	if _, ok := db.users[userID]; !ok {
		return fmt.Errorf("user %s does not exist", userID)
	}
	if db.members[groupID] == nil {
		db.members[groupID] = make(map[string]bool)
	}
	db.members[groupID][userID] = true
	return nil
}

// IsMember checks if a user is a member of a group.
func (db *InMemDB) IsMember(groupID, userID string) bool {
	db.mu.RLock()
	defer db.mu.RUnlock()
	if db.members[groupID] == nil {
		return false
	}
	return db.members[groupID][userID]
}

// InsertRequest inserts a request checking RLS insert constraints.
func (db *InMemDB) InsertRequest(req Request) error {
	db.mu.Lock()
	defer db.mu.Unlock()

	// 1. Verify group membership (defense-in-depth handler rule mirroring public.is_group_member)
	m, ok := db.members[req.GroupID]
	if !ok {
		return fmt.Errorf("group %s not found", req.GroupID)
	}
	if _, isMember := m[req.RequestedBy]; !isMember {
		return fmt.Errorf("user %s is not a member of the group", req.RequestedBy)
	}

	// 2. RLS Constraint: If is_private is true, private_to must be not null and must be a member of the group
	if req.IsPrivate {
		if req.PrivateTo == nil || *req.PrivateTo == "" {
			return fmt.Errorf("private request must specify private_to")
		}
		if _, isPrivateToMember := m[*req.PrivateTo]; !isPrivateToMember {
			return fmt.Errorf("private_to user %s must be a member of the group", *req.PrivateTo)
		}
	} else {
		if req.PrivateTo != nil {
			return fmt.Errorf("public requests must have private_to as null")
		}
	}

	db.requests = append(db.requests, req)
	return nil
}

// GetRequests returns requests visible to a user under SELECT RLS policies.
func (db *InMemDB) GetRequests(groupID, userID string) ([]Request, error) {
	db.mu.RLock()
	defer db.mu.RUnlock()

	// Verify group membership (defense-in-depth handler rule mirroring public.is_group_member)
	m, ok := db.members[groupID]
	if !ok {
		return nil, fmt.Errorf("group %s not found", groupID)
	}
	if _, isMember := m[userID]; !isMember {
		// RLS select policy returns empty set for non-members
		return []Request{}, nil
	}

	var visible []Request
	for _, req := range db.requests {
		if req.GroupID != groupID {
			continue
		}
		// RLS READ Policy: (is_private = false OR requested_by = auth.uid() OR private_to = auth.uid())
		if !req.IsPrivate || req.RequestedBy == userID || (req.PrivateTo != nil && *req.PrivateTo == userID) {
			visible = append(visible, req)
		}
	}
	return visible, nil
}

// buildIsolationTestApp builds the Fiber router connected to the simulated database.
func buildIsolationTestApp(db *InMemDB) *fiber.App {
	app := fiber.New()

	// Manual CORS middleware
	app.Use(func(c *fiber.Ctx) error {
		c.Set("Access-Control-Allow-Origin", "*")
		c.Set("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS")
		c.Set("Access-Control-Allow-Headers", "Origin,Content-Type,Authorization,Accept")
		if c.Method() == "OPTIONS" {
			return c.SendStatus(204)
		}
		return c.Next()
	})

	// Simple auth middleware simulating JWT extraction from "Bearer <user_id>"
	mockAuthRequired := func(c *fiber.Ctx) error {
		if c.Method() == "OPTIONS" {
			return c.Next()
		}

		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Missing authorization header",
			})
		}

		var token string
		n, err := fmt.Sscanf(authHeader, "Bearer %s", &token)
		if err != nil || n != 1 || token == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid or expired authorization token",
			})
		}

		c.Locals("userID", token)
		return c.Next()
	}

	api := app.Group("/api")
	v1 := api.Group("/v1")

	// Public Auth Register
	v1.Post("/auth/register", func(c *fiber.Ctx) error {
		var body struct {
			ID          string `json:"id"`
			DisplayName string `json:"display_name"`
		}
		if err := c.BodyParser(&body); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
		}
		if body.ID == "" || body.DisplayName == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "missing fields"})
		}
		db.RegisterUser(body.ID, body.DisplayName)
		return c.Status(fiber.StatusCreated).JSON(fiber.Map{
			"id":           body.ID,
			"display_name": body.DisplayName,
		})
	})

	// Protected Endpoints
	protected := v1.Group("", mockAuthRequired)

	// Create Group
	protected.Post("/groups", func(c *fiber.Ctx) error {
		uid := c.Locals("userID").(string)
		var body struct {
			ID       string `json:"id"`
			Name     string `json:"name"`
			JoinCode string `json:"join_code"`
		}
		if err := c.BodyParser(&body); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
		}
		if body.ID == "" || body.Name == "" || body.JoinCode == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "missing fields"})
		}
		if err := db.CreateGroup(body.ID, body.Name, body.JoinCode, uid); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(fiber.StatusCreated).JSON(fiber.Map{
			"id":         body.ID,
			"name":       body.Name,
			"join_code":  body.JoinCode,
			"created_by": uid,
		})
	})

	// Join Group by join_code (group-based joining, not user-based)
	protected.Post("/groups/join", func(c *fiber.Ctx) error {
		uid := c.Locals("userID").(string)
		var body struct {
			JoinCode string `json:"join_code"`
		}
		if err := c.BodyParser(&body); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
		}
		if body.JoinCode == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "missing join_code"})
		}

		groupID, err := db.GetGroupByJoinCode(body.JoinCode)
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": err.Error()})
		}
		if err := db.JoinGroup(groupID, uid); err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"status":   "joined",
			"group_id": groupID,
			"user_id":  uid,
		})
	})

	// Delete Group (soft delete)
	protected.Delete("/groups/:groupId", func(c *fiber.Ctx) error {
		uid := c.Locals("userID").(string)
		groupID := c.Params("groupId")

		// Check if user is member
		isMember := db.IsMember(groupID, uid)

		if !isMember {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "only group members can delete groups",
			})
		}

		if err := db.SoftDeleteGroup(groupID); err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"status":   "deleted",
			"group_id": groupID,
		})
	})

	// Create Request
	protected.Post("/groups/:groupId/requests", func(c *fiber.Ctx) error {
		uid := c.Locals("userID").(string)
		groupID := c.Params("groupId")
		var body struct {
			ItemName  string  `json:"item_name"`
			IsPrivate bool    `json:"is_private"`
			PrivateTo *string `json:"private_to"`
		}
		if err := c.BodyParser(&body); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
		}

		req := Request{
			ID:          fmt.Sprintf("req-%s-%d", groupID, len(db.requests)+1),
			GroupID:     groupID,
			RequestedBy: uid,
			ItemName:    body.ItemName,
			IsPrivate:   body.IsPrivate,
			PrivateTo:   body.PrivateTo,
			Status:      "pending",
		}

		if err := db.InsertRequest(req); err != nil {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": err.Error()})
		}

		return c.Status(fiber.StatusCreated).JSON(req)
	})

	// List Requests
	protected.Get("/groups/:groupId/requests", func(c *fiber.Ctx) error {
		uid := c.Locals("userID").(string)
		groupID := c.Params("groupId")

		reqs, err := db.GetRequests(groupID, uid)
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": err.Error()})
		}

		return c.Status(fiber.StatusOK).JSON(reqs)
	})

	return app
}

// TestE2E_SameHouseMultiUserIsolation runs the true same-house multi-user visibility isolation test.
func TestE2E_SameHouseMultiUserIsolation(t *testing.T) {
	db := NewInMemDB()
	app := buildIsolationTestApp(db)

	const (
		yigitID   = "yigit-111"
		user2ID   = "user2-222"
		user3ID   = "user3-333"
		groupID   = "alpha-123"
		groupName = "House-Alpha"
		groupCode = "a1b2c3d4e5f6"
	)

	// 1. User 1 (Yiğit) - House Creation:
	t.Run("Step 1: User 1 (Yiğit) registers and creates House-Alpha", func(t *testing.T) {
		// Register User 1
		regPayload := map[string]string{
			"id":           yigitID,
			"display_name": "Yiğit",
		}
		regBody, _ := json.Marshal(regPayload)
		reqReg := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewReader(regBody))
		reqReg.Header.Set("Content-Type", "application/json")
		respReg, err := app.Test(reqReg)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusCreated, respReg.StatusCode)

		// Create Group (with join_code)
		groupPayload := map[string]string{
			"id":        groupID,
			"name":      groupName,
			"join_code": groupCode,
		}
		groupBody, _ := json.Marshal(groupPayload)
		reqGroup := httptest.NewRequest(http.MethodPost, "/api/v1/groups", bytes.NewReader(groupBody))
		reqGroup.Header.Set("Content-Type", "application/json")
		reqGroup.Header.Set("Authorization", "Bearer "+yigitID)
		respGroup, err := app.Test(reqGroup)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusCreated, respGroup.StatusCode)

		// Verify membership
		assert.True(t, db.IsMember(groupID, yigitID), "Yiğit should be a member of House-Alpha")
	})

	// 2. User 2 - Group Joining Flow (via join_code):
	t.Run("Step 2: User 2 registers and joins House-Alpha via join_code", func(t *testing.T) {
		// Register User 2
		regPayload := map[string]string{
			"id":           user2ID,
			"display_name": "User 2",
		}
		regBody, _ := json.Marshal(regPayload)
		reqReg := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewReader(regBody))
		reqReg.Header.Set("Content-Type", "application/json")
		respReg, err := app.Test(reqReg)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusCreated, respReg.StatusCode)

		// Join Group via join_code
		joinPayload := map[string]string{
			"join_code": groupCode,
		}
		joinBody, _ := json.Marshal(joinPayload)
		reqJoin := httptest.NewRequest(http.MethodPost, "/api/v1/groups/join", bytes.NewReader(joinBody))
		reqJoin.Header.Set("Content-Type", "application/json")
		reqJoin.Header.Set("Authorization", "Bearer "+user2ID)
		respJoin, err := app.Test(reqJoin)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, respJoin.StatusCode)

		// Verify User 2 is member
		assert.True(t, db.IsMember(groupID, user2ID), "User 2 should be a member of House-Alpha")
	})

	// 3. User 2 - Multi-Tier Request Insertion:
	t.Run("Step 3: User 2 inserts public and private requests into House-Alpha", func(t *testing.T) {
		// Public Request: Ekmek
		req1Payload := map[string]interface{}{
			"item_name":  "Ekmek",
			"is_private": false,
		}
		req1Body, _ := json.Marshal(req1Payload)
		reqReq1 := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/groups/%s/requests", groupID), bytes.NewReader(req1Body))
		reqReq1.Header.Set("Content-Type", "application/json")
		reqReq1.Header.Set("Authorization", "Bearer "+user2ID)
		respReq1, err := app.Test(reqReq1)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusCreated, respReq1.StatusCode)

		// Private Request: Yiğit'e Doğum Günü Hediyesi (private to User 2)
		req2Payload := map[string]interface{}{
			"item_name":  "Yiğit'e Doğum Günü Hediyesi",
			"is_private": true,
			"private_to": user2ID,
		}
		req2Body, _ := json.Marshal(req2Payload)
		reqReq2 := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/groups/%s/requests", groupID), bytes.NewReader(req2Body))
		reqReq2.Header.Set("Content-Type", "application/json")
		reqReq2.Header.Set("Authorization", "Bearer "+user2ID)
		respReq2, err := app.Test(reqReq2)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusCreated, respReq2.StatusCode)
	})

	// 4. Visibility Assertions (Step 1):
	t.Run("Step 4: Verify request visibility for User 2 and User 1 (Yiğit)", func(t *testing.T) {
		// User 2 reads lists
		reqList2 := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/groups/%s/requests", groupID), nil)
		reqList2.Header.Set("Authorization", "Bearer "+user2ID)
		respList2, err := app.Test(reqList2)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, respList2.StatusCode)

		var list2 []Request
		err = json.NewDecoder(respList2.Body).Decode(&list2)
		assert.NoError(t, err)

		// Assert User 2 sees both
		assert.Len(t, list2, 2, "User 2 should see both public and private requests")
		hasEkmek := false
		hasGift := false
		for _, r := range list2 {
			if r.ItemName == "Ekmek" {
				hasEkmek = true
			}
			if r.ItemName == "Yiğit'e Doğum Günü Hediyesi" {
				hasGift = true
			}
		}
		assert.True(t, hasEkmek, "User 2 should see Ekmek")
		assert.True(t, hasGift, "User 2 should see the Birthday Gift request")

		// User 1 (Yiğit) reads lists
		reqList1 := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/groups/%s/requests", groupID), nil)
		reqList1.Header.Set("Authorization", "Bearer "+yigitID)
		respList1, err := app.Test(reqList1)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, respList1.StatusCode)

		var list1 []Request
		err = json.NewDecoder(respList1.Body).Decode(&list1)
		assert.NoError(t, err)

		// Assert Yiğit sees Ekmek but NOT the gift
		assert.Len(t, list1, 1, "Yiğit should only see 1 request")
		assert.Equal(t, "Ekmek", list1[0].ItemName, "The single request visible to Yiğit should be Ekmek")
	})

	// 5. User 3 - Subsequent Group Joining & Final Spy Assertion:
	t.Run("Step 5: User 3 registers, joins, and verifies visibility", func(t *testing.T) {
		// Register User 3
		regPayload := map[string]string{
			"id":           user3ID,
			"display_name": "User 3",
		}
		regBody, _ := json.Marshal(regPayload)
		reqReg := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewReader(regBody))
		reqReg.Header.Set("Content-Type", "application/json")
		respReg, err := app.Test(reqReg)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusCreated, respReg.StatusCode)

		// Join Group via join_code
		joinPayload := map[string]string{
			"join_code": groupCode,
		}
		joinBody, _ := json.Marshal(joinPayload)
		reqJoin := httptest.NewRequest(http.MethodPost, "/api/v1/groups/join", bytes.NewReader(joinBody))
		reqJoin.Header.Set("Content-Type", "application/json")
		reqJoin.Header.Set("Authorization", "Bearer "+user3ID)
		respJoin, err := app.Test(reqJoin)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, respJoin.StatusCode)

		// User 3 reads lists
		reqList3 := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/groups/%s/requests", groupID), nil)
		reqList3.Header.Set("Authorization", "Bearer "+user3ID)
		respList3, err := app.Test(reqList3)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, respList3.StatusCode)

		var list3 []Request
		err = json.NewDecoder(respList3.Body).Decode(&list3)
		assert.NoError(t, err)

		// Assert User 3 sees Ekmek but NOT the gift
		assert.Len(t, list3, 1, "User 3 should only see 1 request")
		assert.Equal(t, "Ekmek", list3[0].ItemName, "The single request visible to User 3 should be Ekmek")
	})
}

// TestE2E_GroupJoinCodeFlow tests the new group-based join_code functionality.
// Each group now has its own join_code, replacing the old user-based unique_code approach.
func TestE2E_GroupJoinCodeFlow(t *testing.T) {
	db := NewInMemDB()
	app := buildIsolationTestApp(db)

	const (
		user1ID           = "user1-aaa"
		user2ID           = "user2-bbb"
		user3ID           = "user3-ccc"
		familyGroupID     = "family-001"
		communityGroupID  = "community-002"
		familyJoinCode    = "abcd1234abcd"
		communityJoinCode = "efgh5678efgh"
	)

	// Helper to register a user
	registerUser := func(t *testing.T, id, name string) {
		payload := map[string]string{"id": id, "display_name": name}
		body, _ := json.Marshal(payload)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusCreated, resp.StatusCode)
	}

	// Helper to create a group
	createGroup := func(t *testing.T, userID, groupID, name, joinCode string) {
		payload := map[string]string{
			"id":        groupID,
			"name":      name,
			"join_code": joinCode,
		}
		body, _ := json.Marshal(payload)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/groups", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+userID)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusCreated, resp.StatusCode)
	}

	// Helper to join group by join_code
	joinByCode := func(t *testing.T, userID, joinCode string) int {
		payload := map[string]string{"join_code": joinCode}
		body, _ := json.Marshal(payload)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/groups/join", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+userID)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		return resp.StatusCode
	}

	// Helper to delete a group
	deleteGroup := func(t *testing.T, userID, groupID string) int {
		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/groups/%s", groupID), nil)
		req.Header.Set("Authorization", "Bearer "+userID)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		return resp.StatusCode
	}

	// ===== SCENARIO 1: Same user creates multiple groups, each has unique join_code =====
	t.Run("Scenario 1: User creates multiple groups with unique join_codes", func(t *testing.T) {
		registerUser(t, user1ID, "User 1")
		createGroup(t, user1ID, familyGroupID, "Family Home", familyJoinCode)
		createGroup(t, user1ID, communityGroupID, "Community Group", communityJoinCode)

		// Verify both groups exist and have different join_codes
		assert.NotEqual(t, familyJoinCode, communityJoinCode, "Each group must have a unique join_code")

		// Verify User 1 is admin of both
		assert.True(t, db.IsMember(familyGroupID, user1ID), "User 1 should be admin of Family Home")
		assert.True(t, db.IsMember(communityGroupID, user1ID), "User 1 should be admin of Community Group")
	})

	// ===== SCENARIO 2: Join by correct join_code joins the RIGHT group =====
	t.Run("Scenario 2: User 2 joins Family Home by its join_code (not the wrong group)", func(t *testing.T) {
		registerUser(t, user2ID, "User 2")

		// Join Family Home by its specific join_code
		status := joinByCode(t, user2ID, familyJoinCode)
		assert.Equal(t, http.StatusOK, status, "Should successfully join Family Home")

		// User 2 should be in Family Home, NOT in Community Group
		assert.True(t, db.IsMember(familyGroupID, user2ID), "User 2 should be member of Family Home")
		assert.False(t, db.IsMember(communityGroupID, user2ID), "User 2 should NOT be in Community Group")
	})

	// ===== SCENARIO 3: Invalid join_code returns 404 =====
	t.Run("Scenario 3: Invalid join_code returns 404", func(t *testing.T) {
		registerUser(t, user3ID, "User 3")
		status := joinByCode(t, user3ID, "invalidcode1234")
		assert.Equal(t, http.StatusNotFound, status, "Invalid join_code should return 404")
	})

	// ===== SCENARIO 4: Soft-delete group, then try to join by its code =====
	t.Run("Scenario 4: Soft-deleted group's join_code becomes unusable", func(t *testing.T) {
		const deletedGroupID = "deleted-003"
		const deletedJoinCode = "deadbeef0123"

		createGroup(t, user1ID, deletedGroupID, "To Be Deleted", deletedJoinCode)
		assert.True(t, db.IsMember(deletedGroupID, user1ID), "User 1 should be admin of group to be deleted")

		// Delete the group
		status := deleteGroup(t, user1ID, deletedGroupID)
		assert.Equal(t, http.StatusOK, status, "Group admin should be able to delete")

		// Try to join by the deleted group's code → should fail
		// Register a new user
		const user4ID = "user4-ddd"
		registerUser(t, user4ID, "User 4")
		joinStatus := joinByCode(t, user4ID, deletedJoinCode)
		assert.Equal(t, http.StatusNotFound, joinStatus, "Deleted group's join_code should not be joinable")
	})

	// ===== SCENARIO 5: Non-member cannot delete a group =====
	t.Run("Scenario 5: Non-member cannot delete a group", func(t *testing.T) {
		// User 3 (non-member) tries to delete Family Home
		status := deleteGroup(t, user3ID, familyGroupID)
		assert.Equal(t, http.StatusForbidden, status, "Non-member should not be able to delete a group")
	})

	// ===== SCENARIO 6: Group member CAN delete a group =====
	t.Run("Scenario 6: Any group member can delete a group", func(t *testing.T) {
		// User 2 (group member) deletes Family Home
		status := deleteGroup(t, user2ID, familyGroupID)
		assert.Equal(t, http.StatusOK, status, "Group member should be able to delete a group")

		// Verify group is soft-deleted — can't join by its code anymore
		const user5ID = "user5-eee"
		registerUser(t, user5ID, "User 5")
		joinStatus := joinByCode(t, user5ID, familyJoinCode)
		assert.Equal(t, http.StatusNotFound, joinStatus, "Deleted group's join_code should be unusable")
	})
}
