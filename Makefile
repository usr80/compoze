jade :
	jade .


compile :
	browserify -t coffeeify  script/composer.js -o composer.js


deploy :
	jade .
	git commit -am "deploy"
	git push