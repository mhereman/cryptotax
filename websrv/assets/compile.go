package assets

//#go:generate sass --style compressed ./src/static/css/stylesheet.scss ./static/css/stylesheet.min.css
//go:generate sass ./src/static/css/stylesheet.scss ./static/css/stylesheet.min.css

// Minify js files
//#go:generate yuicompressor --type js --nomunge ../websrv/fs/src/static/js/flash.js -o ../websrv/fs/src/static/js-min/flash.min.js
//#go:generate yuicompressor --type js --nomunge ../websrv/fs/src/static/js/init.js -o ../websrv/fs/src/static/js-min/init.min.js
//#go:generate yuicompressor --type js --nomunge ../websrv/fs/src/static/js/utils.js -o ../websrv/fs/src/static/js-min/utils.min.js
//#go:generate sh -c "go run ../generators/cmd/cat/main.go -in ../websrv/fs/src/static/js-min -pattern '*.min.js' -out ../websrv/fs/static/js/script.min.js"

//go:generate sh -c "go run ../../generators/cat/main.go -in ./src/static/js -pattern '*.js' -out ./static/js/app.js"
