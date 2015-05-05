jade :
	jade .

jison :
	jison script/grammer.jison -o script/grammer.js
compile :
	browserify -t coffeeify  src/compoze.js -o dist/compoze.js
	cp dist/compoze.js lib/editor.md/lib/compoze.js

deploy :
	jade .
	git commit -am "deploy"
	git push

sync :
	qrsync qiniu.conf