package main

import (
	"fmt"
)

type ListNode struct {
	Val  int
	Next *ListNode
}

func buildListNode(values []int) (root *ListNode) {
	if len(values) == 0 {
		return nil
	}
	root = &ListNode{Val: values[0]}
	node := root
	for _, val := range values[1:] {
		node.Next = &ListNode{Val: val}
		node = node.Next
	}
	return
}

func getNumber(node *ListNode) (ret int) {
	for node != nil {
		ret = ret*10 + node.Val
		node = node.Next
	}
	return
}

func toList(root *ListNode) (ret []int) {
	for node := root; node != nil; node = node.Next {
		ret = append(ret, node.Val)
	}
	return
}

func iterateNode(node *ListNode) (int, *ListNode) {
	if node == nil {
		return 0, nil
	}
	return node.Val, node.Next
}

func addTwoNumbers(l1 *ListNode, l2 *ListNode) *ListNode {
	sum_root := &ListNode{0, nil}
	node := sum_root
	plusOne := false

	for l1 != nil || l2 != nil {
		v1, n1 := iterateNode(l1)
		l1 = n1
		v2, n2 := iterateNode(l2)
		l2 = n2

		current := v1 + v2
		if plusOne {
			current++
		}

		plusOne = current > 9
		node.Next = &ListNode{current % 10, nil}
		node = node.Next
	}
	if plusOne {
		node.Next = &ListNode{1, nil}
	}

	return sum_root.Next
}

func main() {
	var l1, l2 = []int{2, 4, 3}, []int{5, 6, 4}
	fmt.Println(getNumber(buildListNode(l1)))
	fmt.Println(l2)

	n := addTwoNumbers(buildListNode(l1), buildListNode(l2))

	fmt.Println(toList(n))

}
