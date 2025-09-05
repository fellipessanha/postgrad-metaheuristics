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

func longestPalindrome(s string) string {
	var currentLongest string = string(s[0])

	for i, char := range s {
		search := s[i:]
		for j := strings.LastIndexByte(search, byte(char)); j < len(search) && j != -1; j = strings.LastIndexByte(search[:j], byte(char)) {
			substr := search[:j+1]
			println(substr)
			if len(substr) > len(currentLongest) && isPalindrome(substr) {
				currentLongest = substr
			}
		}
	}
	return currentLongest
}

func main() {
	found := longestPalindrome("oi eu sou o abba goku")
	println("found: ", found)

}
