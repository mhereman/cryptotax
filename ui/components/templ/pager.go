package templ

import "html/template"

func init() {
	// Pager
	// $pager := Pager id currPage numPages numShown onSetPage
	funcmap["Pager"] = componentPager
}

func componentPager(
	id string, currpage int, numpages int, numshown int, onsetpage string,
) tmplData {
	pager := []int{}
	from := max(1, min(currpage-numshown, numpages-(2*numshown)))
	for i := range (2 * numshown) + 1 {
		if from+i <= numpages {
			pager = append(pager, from+i)
		}
	}

	return tmplData{
		"Id":        id,
		"Page":      currpage,
		"NumPages":  numpages,
		"Pager":     pager,
		"OnSetPage": template.JS(onsetpage),
	}
}
