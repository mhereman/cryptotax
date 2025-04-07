package cryptodb

import (
	"fmt"

	"github.com/shopspring/decimal"
)

type FiatFormatOption int

const FiatFormatZeroDash FiatFormatOption = 1
const FiatFormatNegativeParenteses FiatFormatOption = 2
const FiatFormatFullPrecision = 3

type FiatAsset struct {
	Asset             string
	Name              string
	Symbol            string
	SymbolBeforeValue bool
}

func (a FiatAsset) Format(d decimal.Decimal, options ...FiatFormatOption) string {
	opts := map[FiatFormatOption]struct{}{}
	for _, o := range options {
		opts[o] = struct{}{}
	}

	parentheses := false
	if _, ok := opts[FiatFormatNegativeParenteses]; ok && d.IsNegative() {
		parentheses = true
		d = d.Neg()
	}

	var v string
	if _, ok := opts[FiatFormatZeroDash]; ok && d.IsZero() {
		v = "—"
	} else {
		if _, ok := opts[FiatFormatFullPrecision]; ok {
			v = fmt.Sprintf("%v", d)
		} else {
			v = d.StringFixed(2)
		}
	}

	if a.SymbolBeforeValue {
		v = fmt.Sprintf("%s %s", a.Symbol, v)
	} else {
		v = fmt.Sprintf("%s %s", v, a.Symbol)
	}

	if parentheses {
		v = fmt.Sprintf("(%s)", v)
	}
	return v
}

type CryptoAsset struct {
	Asset     string
	Name      string
	Precision int
}

func (a CryptoAsset) Format(d decimal.Decimal) string {
	return fmt.Sprintf(
		"%s %s",
		d.Round(int32(a.Precision)).String(),
		a.Asset)
}

func LoadFiatAssets() ([]*FiatAsset, error) {
	const query = `SELECT
		Asset, Name, Symbol, SymbolBeforeValue
	FROM crypto.FiatAssets;`
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	assets := make([]*FiatAsset, 0)
	for rows.Next() {
		var a FiatAsset
		err := rows.Scan(
			&a.Asset, &a.Name, &a.Symbol, &a.SymbolBeforeValue)
		if err != nil {
			return nil, err
		}
		assets = append(assets, &a)
	}
	return assets, nil
}

func LoadCryptoAssets() ([]*CryptoAsset, error) {
	const query = `SELECT
		Asset, Name, Precision
	FROM crypto.Assets;`
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	assets := make([]*CryptoAsset, 0)
	for rows.Next() {
		var a CryptoAsset
		err := rows.Scan(&a.Asset, &a.Name, &a.Precision)
		if err != nil {
			return nil, err
		}
		assets = append(assets, &a)
	}
	return assets, nil
}

func GetConfiguredFiatAsset() (asset *FiatAsset, err error) {
	asset = &FiatAsset{}

	const query = `SELECT
		Asset, Name, Symbol, SymbolBeforeValue
	FROM crypto.FiatAssets
	WHERE Asset IN (
		select Value
    	from crypto.Settings
    	where Name = 'FiatAsset'
	) LIMIT 1;`
	row := db.QueryRow(query)
	err = row.Scan(
		&asset.Asset, &asset.Name, &asset.Symbol, &asset.SymbolBeforeValue)
	if err != nil {
		asset = nil
		return
	}
	return
}
