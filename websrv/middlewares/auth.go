package middlewares

import (
	"net/http"

	"github.com/mhereman/cryptotax/backend/cryptodb"
	"github.com/mhereman/cryptotax/websrv"
)

var InitializeHandlerFunc http.HandlerFunc
var LoginHandlerFunc http.HandlerFunc

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

		next.ServeHTTP(w, websrv.AddClaimsToContext(r, claims))
		/*ctx := context.WithValue(r.Context(), websrv.JWTContextKey, claims)
		next.ServeHTTP(w, r.WithContext(ctx))*/
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
