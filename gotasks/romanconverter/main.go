package main

import "fmt"

func main() {

	fmt.Println(roman(50))
}

func roman(n int) string {
	var str string
	type converter struct {
		num      int
		units    string
		tens     string
		hundreds string
		kl       string
	}

	c := []converter{
		converter{0, "", "", "", ""},
		converter{1, "I", "X", "C", "M"},
		converter{2, "II", "XX", "CC", "MM"},
		converter{3, "III", "XXX", "CCC", "MMM"},
		converter{4, "IV", "XL", "CD", ""},
		converter{5, "V", "L", "D", ""},
		converter{6, "VI", "LX", "CD", ""},
		converter{7, "VII", "LXX", "DCC", ""},
		converter{8, "VIII", "LXXX", "DCCC", ""},
		converter{9, "IX", "XC", "CM", ""},
	}

	var a []int
	for {
		i := n % 10

		if n == 0 {
			break
		} else {
			a = append(a, i)
		}
		n = n / 10
	}

	switch l := len(a); l {
	case 1:
		str = fmt.Sprintf("%s", c[a[0]].units)
	case 2:
		str = fmt.Sprintf("%s%s", c[a[1]].tens, c[a[0]].units)
	case 3:
		str = fmt.Sprintf("%s%s%s", c[a[2]].hundreds, c[a[1]].tens, c[a[0]].units)
	case 4:
		str = fmt.Sprintf("%s%s%s%s", c[a[3]].kl, c[a[2]].hundreds, c[a[1]].tens, c[a[0]].units)

	}
	return str
}

