package handlers

import (
	"html/template"
	"net/http"

	"github.com/mhereman/cryptotax/backend/cryptodb"
)

type transactionsAddData struct {
	TransactionType int
}

type transactionsAddInitialisationData struct {
	FiatAsset      *cryptodb.FiatAsset
	FiatAssetMap   map[string]*cryptodb.FiatAsset
	CryptoAssetMap map[string]*cryptodb.CryptoAsset
}

type transactionsAddTradeData struct {
	FiatAsset      *cryptodb.FiatAsset
	FiatAssetMap   map[string]*cryptodb.FiatAsset
	CryptoAssetMap map[string]*cryptodb.CryptoAsset
}

type transactionsAddTxFeeData struct {
	FiatAsset      *cryptodb.FiatAsset
	FiatAssetMap   map[string]*cryptodb.FiatAsset
	CryptoAssetMap map[string]*cryptodb.CryptoAsset
}

func TransactionsAdd(templates *template.Template) Handler {
	return func(w http.ResponseWriter, r *http.Request) {
		txType := getIntArgument(r, "txtype", 2)

		transactionsAddData := &transactionsAddData{
			TransactionType: txType,
		}

		if err := templates.ExecuteTemplate(
			w, "transactions_add.html",
			transactionsAddData,
		); err != nil {
			panic(err)
		}
	}
}

func TransactionsAddInitialisation(templates *template.Template) Handler {
	return func(w http.ResponseWriter, r *http.Request) {
		transactionsAddInitialisationData := &transactionsAddInitialisationData{}

		if fa, fam, cam, err := getAssetInfo(); err != nil {
			panic(err)
		} else {
			transactionsAddInitialisationData.FiatAsset = fa
			transactionsAddInitialisationData.FiatAssetMap = fam
			transactionsAddInitialisationData.CryptoAssetMap = cam
		}

		if err := templates.ExecuteTemplate(
			w, "transactions_add_initialisation.html",
			transactionsAddInitialisationData,
		); err != nil {
			panic(err)
		}
	}
}

func TransactionsAddTrade(templates *template.Template) Handler {
	return func(w http.ResponseWriter, r *http.Request) {
		transactionsAddTradeData := &transactionsAddTradeData{}

		if fa, fam, cam, err := getAssetInfo(); err != nil {
			panic(err)
		} else {
			transactionsAddTradeData.FiatAsset = fa
			transactionsAddTradeData.FiatAssetMap = fam
			transactionsAddTradeData.CryptoAssetMap = cam
		}

		if err := templates.ExecuteTemplate(
			w, "transactions_add_trade.html",
			transactionsAddTradeData,
		); err != nil {
			panic(err)
		}
	}
}

func TransactionsAddTxFee(templates *template.Template) Handler {
	return func(w http.ResponseWriter, r *http.Request) {
		transactionsAddTxFeeData := &transactionsAddTxFeeData{}

		if fa, fam, cam, err := getAssetInfo(); err != nil {
			panic(err)
		} else {
			transactionsAddTxFeeData.FiatAsset = fa
			transactionsAddTxFeeData.FiatAssetMap = fam
			transactionsAddTxFeeData.CryptoAssetMap = cam
		}

		if err := templates.ExecuteTemplate(
			w, "transactions_add_txfee.html",
			transactionsAddTxFeeData,
		); err != nil {
			panic(err)
		}
	}
}
