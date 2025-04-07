package websrv

import (
	"context"
	"crypto/ed25519"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/mhereman/cryptotax/config"
)

type jwtContextKey string

const JWTContextKey = jwtContextKey("jwt")

const jwtCookieName = "cryptotax.jwt"

var privFile string
var pubFile string

const (
	jwtIssuer      = "mhereman/cryptotax"
	jwtAudience    = "mhereman/cryptotax"
	jwtTTL         = time.Hour
	jwtAutoRefresh = 5 * time.Minute
)

type customClaims struct {
	IsAdmin bool `json:"is_admin"`
	jwt.RegisteredClaims
}

func (c customClaims) GetUser() string {
	return c.Subject
}

func (c customClaims) IsAdministrator() bool {
	return c.IsAdmin
}

func CreateJWT(w http.ResponseWriter, user string, isAdmin bool) error {
	privKey, err := getJWTPrivKey()
	if err != nil {
		return err
	}

	claims := customClaims{
		IsAdmin: isAdmin,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    jwtIssuer,
			Subject:   user,
			Audience:  []string{jwtAudience},
			ExpiresAt: &jwt.NumericDate{Time: time.Now().Add(jwtTTL)},
			NotBefore: &jwt.NumericDate{Time: time.Now()},
			IssuedAt:  &jwt.NumericDate{Time: time.Now()},
		},
	}
	token := jwt.NewWithClaims(&jwt.SigningMethodEd25519{}, claims)
	stoken, err := token.SignedString(privKey)
	if err != nil {
		return err
	}

	setJWTCookie(w, stoken)
	return nil
}

func ValidateJWT(w http.ResponseWriter, r *http.Request) (*customClaims, error) {
	stoken, err := getJWTCookie(r)
	if err != nil {
		return nil, err
	}

	tokenClaims := customClaims{}
	token, err := jwt.ParseWithClaims(stoken, &tokenClaims, func(t *jwt.Token) (interface{}, error) {
		pubKey, err := getJWTPubKey()
		if err != nil {
			return nil, err
		}
		return pubKey, nil
	})

	if err != nil {
		return nil, err
	}
	if !token.Valid {
		return nil, fmt.Errorf("invalid token")
	}

	if time.Now().Add(jwtAutoRefresh).After(tokenClaims.ExpiresAt.Time) {
		refreshJWT(w, &tokenClaims)
	}

	return &tokenClaims, nil
}

func RemoveJWT(w http.ResponseWriter) {
	clearJWTCookie(w)
}

func AddClaimsToContext(r *http.Request, claims *customClaims) *http.Request {
	ctx := context.WithValue(r.Context(), JWTContextKey, claims)
	return r.WithContext(ctx)
}

func GetClaimsFromContext(r *http.Request) *customClaims {
	ctx := r.Context()
	return ctx.Value(JWTContextKey).(*customClaims)
}

func refreshJWT(w http.ResponseWriter, origClaims *customClaims) {
	user := origClaims.Subject
	isAdmin := origClaims.IsAdmin
	if err := CreateJWT(w, user, isAdmin); err != nil {
		log.Printf("Failed to refresh jwt: %v", err)
	}
}

func initFileNames() {
	if pubFile == "" {
		pubFile = fmt.Sprintf("%s/pub.key", config.LibDir())
	}
	if privFile == "" {
		privFile = fmt.Sprintf("%s/priv.key", config.LibDir())
	}
}

func jwtKeysExists() bool {
	initFileNames()

	privInf, err := os.Stat(privFile)
	if err != nil || privInf.IsDir() {
		return false
	}

	pubInf, err := os.Stat(pubFile)
	if err != nil || pubInf.IsDir() {
		return false
	}

	return true
}

func generateJWTKeyPair() error {
	initFileNames()
	if jwtKeysExists() {
		return nil
	}

	pubKey, privKey, err := ed25519.GenerateKey(nil)
	if err != nil {
		return err
	}

	err = os.WriteFile(pubFile, pubKey, 0644)
	if err != nil {
		return err
	}

	err = os.WriteFile(privFile, privKey, 0600)
	if err != nil {
		return err
	}

	return nil
}

func getJWTKeyPair() (ed25519.PublicKey, ed25519.PrivateKey, error) {
	pubKey, err := getJWTPubKey()
	if err != nil {
		return nil, nil, err
	}
	privKey, err := getJWTPrivKey()
	if err != nil {
		return nil, nil, err
	}
	return pubKey, privKey, nil
}

func getJWTPubKey() (ed25519.PublicKey, error) {
	initFileNames()
	if !jwtKeysExists() {
		return nil, fmt.Errorf("jwt keys not found")
	}

	pubKey, err := os.ReadFile(pubFile)
	if err != nil {
		return nil, err
	}
	return pubKey, nil
}

func getJWTPrivKey() (ed25519.PrivateKey, error) {
	initFileNames()
	if !jwtKeysExists() {
		return nil, fmt.Errorf("jwt keys not found")
	}

	privKey, err := os.ReadFile(privFile)
	if err != nil {
		return nil, err
	}
	return privKey, nil
}

func setJWTCookie(w http.ResponseWriter, jwt string) {
	c := &http.Cookie{
		Name:     jwtCookieName,
		Path:     "/",
		Value:    jwt,
		HttpOnly: true,
		MaxAge:   0,
	}
	http.SetCookie(w, c)
}

func getJWTCookie(r *http.Request) (
	jwt string,
	err error,
) {
	c, err := r.Cookie(jwtCookieName)
	if err != nil {
		switch err {
		case http.ErrNoCookie:
			return "", nil
		default:
			return
		}
	}

	jwt = c.Value
	return
}

func clearJWTCookie(w http.ResponseWriter) {
	c := &http.Cookie{
		Name:     jwtCookieName,
		Path:     "/",
		Value:    "",
		HttpOnly: true,
		MaxAge:   -1,
	}
	http.SetCookie(w, c)
}
