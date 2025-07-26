## 一个简单干净好看的电子书阅读器~

 - 轻量级,只支持txt格式电子书~
 - 简单~ 没有多余功能
 - 第三条想好了再写,感觉有第三行好看嗷...

### 构建

```bash
# 设置构建目录
meson setup builddir
# 编译
meson compile -C builddir
# 运行
GSETTINGS_SCHEMA_DIR="../data" ./reader
```
##### 待完成的事项QwQ  

###### ✨ 最近阅读
###### X 自动选择章节匹配表达式
###### X 自动填写作者信息
###### X i18n多语言（虽然 不会 做 XwX）