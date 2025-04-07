package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/mhereman/cryptotax/backend/cryptodb"
	"github.com/shopspring/decimal"
)

func getCurrentYear() int {
	return time.Now().Year()
}

func getIntArgument(r *http.Request, key string, defaultValue int) int {
	if v := r.URL.Query().Get(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return defaultValue
}

func getPageSizeArgument(r *http.Request) int {
	return getIntArgument(r, "pagesize", 10)
}

func getPageArgument(r *http.Request, def int) int {
	return getIntArgument(r, "page", def)
}

func getAssetInfo() (
	fiatAsset *cryptodb.FiatAsset,
	fiatAssetMap map[string]*cryptodb.FiatAsset,
	cryptoAssetMap map[string]*cryptodb.CryptoAsset,
	err error,
) {
	var farr []*cryptodb.FiatAsset
	var carr []*cryptodb.CryptoAsset

	if fiatAsset, err = cryptodb.GetConfiguredFiatAsset(); err != nil {
		return
	}
	if farr, err = cryptodb.LoadFiatAssets(); err != nil {
		return
	}
	if carr, err = cryptodb.LoadCryptoAssets(); err != nil {
		return
	}

	fiatAssetMap = make(map[string]*cryptodb.FiatAsset)
	for _, a := range farr {
		fiatAssetMap[a.Asset] = a
	}

	cryptoAssetMap = make(map[string]*cryptodb.CryptoAsset)
	for _, a := range carr {
		cryptoAssetMap[a.Asset] = a
	}
	return
}

func formatAsset(
	d *decimal.Decimal, asset string, isFiat bool,
	fiatAsset *cryptodb.FiatAsset,
	fiatAssetMap map[string]*cryptodb.FiatAsset,
	cryptoAssetMap map[string]*cryptodb.CryptoAsset,
) string {
	if !isFiat {
		return cryptoAssetMap[asset].Format(*d)
	}
	if asset == "" {
		return fiatAsset.Format(*d)
	}
	return fiatAssetMap[asset].Format(*d)
}
