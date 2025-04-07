package websrv

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
)

type FlashData struct {
	Value   string `json:"value"`
	Trigger string `json:"trigger"`
}

func SetFlashCookie(w http.ResponseWriter, name string, value []byte, trigger ...string) {
	fd := FlashData{
		Value: base64.StdEncoding.EncodeToString(value),
		Trigger: func() string {
			if len(trigger) > 0 {
				return trigger[0]
			}
			return ""
		}(),
	}
	bytes, _ := json.Marshal(fd)
	c := &http.Cookie{
		Name:     fmt.Sprintf("flash-%s", name),
		Path:     "/",
		Value:    base64.URLEncoding.EncodeToString(bytes),
		HttpOnly: true,
		MaxAge:   0,
	}
	http.SetCookie(w, c)
}

func SetStringFlashCookie(w http.ResponseWriter, name string, value string, trigger ...string) {
	SetFlashCookie(w, name, []byte(value), trigger...)
}

func GetFlashCookie(w http.ResponseWriter, r *http.Request, name string) (
	value []byte,
	trigger string,
	err error,
) {
	defer func() {
		dc := &http.Cookie{
			Name:     fmt.Sprintf("flash-%s", name),
			Path:     "/",
			Value:    "",
			HttpOnly: true,
			MaxAge:   -1,
		}
		http.SetCookie(w, dc)
	}()

	c, err := r.Cookie(fmt.Sprintf("flash-%s", name))
	if err != nil {
		switch err {
		case http.ErrNoCookie:
			return nil, "", nil
		default:
			return
		}
	}

	fd := &FlashData{}
	data, err := base64.URLEncoding.DecodeString(c.Value)
	if err != nil {
		return
	}
	err = json.Unmarshal(data, fd)
	if err != nil {
		return
	}

	value, err = base64.StdEncoding.DecodeString(fd.Value)
	if err != nil {
		return
	}
	trigger = fd.Trigger
	return
}

func GetStringFlashCookie(w http.ResponseWriter, r *http.Request, name string) (
	value string,
	trigger string,
	err error,
) {
	bytes, trigger, err := GetFlashCookie(w, r, name)
	if err != nil {
		return
	}
	value = string(bytes)
	return
}
