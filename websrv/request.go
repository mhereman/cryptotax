package websrv

import (
	"fmt"
	"net/http"
	"net/url"
	"strconv"
)

func PathArg(r *http.Request, name string) (val string, err error) {
	val, _ = url.PathUnescape(r.PathValue(name))
	if val == "" {
		err = fmt.Errorf("missing path argument: %s", name)
	}
	return
}

func PathArgInt(r *http.Request, name string) (val int, err error) {
	str, err := PathArg(r, name)
	if err != nil {
		return
	}
	val, err = strconv.Atoi(str)
	return
}

func QueryArg(r *http.Request, name string) string {
	v, _ := url.QueryUnescape(r.URL.Query().Get(name))
	return v
}

func QueryArgInt(r *http.Request, name string, def int) (val int) {
	str := QueryArg(r, name)
	if str == "" {
		val = def
		return
	}
	val, err := strconv.Atoi(str)
	if err != nil {
		val = def
		return
	}
	return
}

func QueryArgList(r *http.Request, name string) []string {
	lst, ok := r.URL.Query()[name]
	if !ok {
		return nil
	}

	res := make([]string, 0, len(lst))
	for _, a := range lst {
		v, _ := url.QueryUnescape(a)
		res = append(res, v)
	}
	return res
}

func QueryArgListInt(r *http.Request, name string) []int {
	strLst := QueryArgList(r, name)
	if strLst == nil {
		return nil
	}
	lst := make([]int, 0, len(strLst))
	for _, s := range strLst {
		val, err := strconv.Atoi(s)
		if err != nil {
			val = 0
		}
		lst = append(lst, val)
	}
	return lst
}
