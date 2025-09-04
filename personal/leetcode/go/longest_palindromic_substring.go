package main

import (
	"strings"
)

func isPalindrome(s string) bool {
	for idx, char := range s {
		if s[len(s)-idx-1] != byte(char) {
			return false
		}
		if idx > len(s)/2 {
			break
		}
	}
	return true
}

func find(s string, c rune, l int = 0, r int)

func longestPalindrome(s string) string {
	var currentLongest string = string(s[0])

	for i, char := range s {
		firstSearch := s[i:]
		for j := strings.IndexRune(firstSearch[i+1:], char); j != 1; j = j + strings.IndexRune(firstSearch[j+1:], char) {
			substr := firstSearch[i:j]
			println(substr)
			if len(substr) > len(currentLongest) && isPalindrome(substr) {
				currentLongest = substr
			}
		}
	}
	return currentLongest
}

func main() {
	longestPalindrome("oi eu sou o goku")
}
