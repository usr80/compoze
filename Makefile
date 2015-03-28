jade :
	jade .


compile :
	browserify -t coffeeify  script/composer.js -o composer.js


deploy :
	jade .
	git commit -m "deploy"
	git push