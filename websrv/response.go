package websrv

import (
	"encoding/json"
	"errors"
	"fmt"
	"html/template"
	"io"
	"log"
	"net/http"
	"os"

	"github.com/mhereman/cryptotax/websrv/assets"
)

func RenderHtmlTemplate(
	w http.ResponseWriter,
	r *http.Request,
	tmplName string,
	data any,
	trigger ...string,
) {
	buffer := Buffer()
	defer ReleaseBuffer(buffer)

	if err := assets.Templates.ExecuteTemplate(buffer, tmplName, data); err != nil {
		InternalServerError(w, r, err)
		log.Printf("RenderHtmlTemplate Error: %v", err)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if len(trigger) > 0 {
		w.Header().Set("HX-Trigger", trigger[0])
	}
	buffer.WriteTo(w)
}

func RenderHtmlPage(
	w http.ResponseWriter,
	r *http.Request,
	pageName string,
	data any,
	trigger ...string,
) {
	buffer := Buffer()
	defer ReleaseBuffer(buffer)

	if err := assets.Pages.ExecutePage(buffer, pageName, data); err != nil {
		InternalServerError(w, r, err)
		log.Printf("RenderHtmlPage Error: %v", err)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if len(trigger) > 0 {
		w.Header().Set("HX-Trigger", trigger[0])
	}
	buffer.WriteTo(w)
}

func RenderHtmlString(
	w http.ResponseWriter,
	r *http.Request,
	html template.HTML,
	trigger ...string,
) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if len(trigger) > 0 {
		w.Header().Set("HX-Trigger", trigger[0])
	}
	w.Write([]byte(html))
}

func RenderJson(
	w http.ResponseWriter,
	r *http.Request,
	obj any,
) {
	bytes, err := json.Marshal(obj)
	if err != nil {
		InternalServerError(w, r, err)
		log.Printf("RenderJson Error: %v", err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Write(bytes)
}

type SendFileOpt struct {
	Name  string
	Value string
}

func SendFileRefreshOpt() SendFileOpt {
	return SendFileOpt{
		Name:  "HX-Refresh",
		Value: "true",
	}
}

func SendFileRedirectOpt(url string) SendFileOpt {
	return SendFileOpt{
		Name:  "HX-Redirect",
		Value: url,
	}
}

func SendFile(
	w http.ResponseWriter,
	r *http.Request,
	filePath string,
	fileName string,
	contentType string,
	asAttachment bool,
	opts ...SendFileOpt,
) {

	fi, err := os.Stat(filePath)
	if errors.Is(err, os.ErrNotExist) {
		NotFound(w, r)
		return
	}

	fh, err := os.Open(filePath)
	if err != nil {
		NotFound(w, r)
		return
	}
	defer fh.Close()

	if asAttachment {
		w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%s", fileName))
		w.Header().Set("Content-Type", contentType)
		w.Header().Set("Content-Length", fmt.Sprintf("%d", fi.Size()))
	}
	for _, opt := range opts {
		switch opt.Name {
		case "HX-Refresh", "HX-Redirect":
			w.Header().Set(opt.Name, opt.Value)
		}
	}
	io.Copy(w, fh)
}

func Redirect(
	w http.ResponseWriter,
	r *http.Request,
	path string,
	status int,
) {
	http.Redirect(w, r, path, status)
}

func NoContent(
	w http.ResponseWriter,
	r *http.Request,
) {
	w.WriteHeader(http.StatusNoContent)
	w.Write([]byte(""))
}

func NotFound(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(fmt.Sprintf("Page not found: %s", r.URL)))
}

func InternalServerError(w http.ResponseWriter, r *http.Request, err error) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusInternalServerError)
	if debug {
		w.Write([]byte(fmt.Sprintf("Internal Server Error: %s", err)))
	} else {
		w.Write([]byte("Internal Server Error"))
	}
}

func Unauthorized(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusUnauthorized)
	w.Write([]byte("Unauthorized"))
}
