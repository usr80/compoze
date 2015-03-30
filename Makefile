jade :
	jade .


compile :
	jison script/grammer.jison -o script/grammer.js
	browserify -t coffeeify  script/compoze.js -o compoze.js


deploy :
	jade .
	git commit -am "deploy"
	git push