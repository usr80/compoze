
![compoze](http://compoze.coding.io/demo/resource/compoze.png)

compoze 可编辑在线乐谱

http://compoze.coding.io/

#使用方法
1. 加载js文件
```
 <script src="dist/compoze.js"></script>
```

2. 自动解析.compoze 元素里面的内容,解析生成Canvas乐谱
```
<div class="compoze"> 
    tabstave notation=true tablature=false
    notes 4-5-6/3 ## =|: 5-4-2/3 2/2 =:|
</div>
```

更多语法请参考 [compoze语法介绍](http://compoze.coding.io/demo/html/helper.html)


#开发指引
安装browserify

`npm install browserify -g`

执行命令 `make compile` 打包输出dist/compoze.js
