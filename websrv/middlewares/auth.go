package middlewares

import (
	"context"
	"errors"
	"net/http"

	"github.com/mhereman/cryptotax/backend/cryptodb"
	"github.com/mhereman/cryptotax/websrv"
	"github.com/mhereman/cryptotax/websrv/errmsg"
)

var InitializeHandlerFunc http.HandlerFunc
var LoginHandlerFunc http.HandlerFunc

type userContextKey string

const UserContextKey = userContextKey("user")

func addUserToContext(r *http.Request, userData *websrv.UserData) *http.Request {
	ctx := context.WithValue(r.Context(), UserContextKey, userData)
	return r.WithContext(ctx)
}

func GetUserFromContext(r *http.Request) *websrv.UserData {
	ctx := r.Context()
	return ctx.Value(UserContextKey).(*websrv.UserData)
}

func Auth(next http.HandlerFunc) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ok, err := cryptodb.IsAdminConfigured()
		if err != nil {
			websrv.InternalServerError(w, r, err)
			return
		}
		if !ok {
			InitializeHandlerFunc.ServeHTTP(w, r)
			return
		}

		claims, err := websrv.ValidateJWT(w, r)
		if err != nil {
			LoginHandlerFunc.ServeHTTP(w, r)
			return
		}

		userData := websrv.NewUserDataFromClaims(r)
		if userData == nil {
			websrv.InternalServerError(w, r, errors.New(errmsg.MsgUserNotFound))
			return
		}

		next.ServeHTTP(w, addUserToContext(websrv.AddClaimsToContext(r, claims), userData))
	})
}

func IsAdmin(next http.HandlerFunc) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userData := GetUserFromContext(r)
		if userData == nil {
			websrv.InternalServerError(w, r, errors.New(errmsg.MsgUserNotFound))
			return
		}
		if !userData.IsAdmin {
			websrv.Forbidden(w, r, errors.New(errmsg.MsgForbidden))
			return
		}
		next.ServeHTTP(w, r)
	})
}

func NoUserPresent(next http.HandlerFunc) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ok, err := cryptodb.IsAdminConfigured()
		if err != nil {
			websrv.InternalServerError(w, r, err)
			return
		}
		if ok {
			websrv.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}

		next.ServeHTTP(w, r)
	})
}
