package service

import (
	"regexp"
	"strings"
	"testing"
)

func TestGenerateUniqueCode(t *testing.T) {
	svc := NewAuthService()

	// Compile the expected regex format: 4 uppercase/numeric chars, a hyphen, 4 uppercase/numeric chars.
	// Note: We only allow the charset we defined (excluding O, 0, I, 1, etc.)
	pattern := `^[A-Z2-9]{4}-[A-Z2-9]{4}$`
	regex, err := regexp.Compile(pattern)
	if err != nil {
		t.Fatalf("Failed to compile regex pattern: %v", err)
	}

	// Run multiple times to verify format and uniqueness (probabilistically)
	codes := make(map[string]bool)
	runs := 100

	for i := 0; i < runs; i++ {
		code, err := svc.GenerateUniqueCode()
		if err != nil {
			t.Fatalf("Unexpected error generating unique code: %v", err)
		}

		// Verify formatting matches regex
		if !regex.MatchString(code) {
			t.Errorf("Code %q does not match pattern %q", code, pattern)
		}

		// Verify confusing characters are excluded
		confusingChars := []string{"0", "O", "1", "I"}
		for _, char := range confusingChars {
			if strings.Contains(code, char) {
				t.Errorf("Code %q contains forbidden confusing character %q", code, char)
			}
		}

		// Track generated code to ensure uniqueness in our small batch
		if codes[code] {
			t.Errorf("Code %q was generated twice in %d runs", code, runs)
		}
		codes[code] = true
	}
}
