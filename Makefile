jade :
	jade .


compile :
	jison script/grammer.jison -o script/grammer.js
	browserify -t coffeeify  script/composer.js -o composer.js


deploy :
	jade .
	git commit -am "deploy"
	git push