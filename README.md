# components是什么
components是SmartCMP云管平台中用于管理各类资源的一种抽象，组件中可以定义: 资源的属性、生命周期及相关脚本

components可以有以下几种常见分类:
- IaaS组件: 计算、网络、存储、负载均衡、弹性IP等等
- PaaS组件: 公有云提供的RDS、Redis等等
- Software组件: MySQL, Oracle, DB2, Tomcat, Nginx, Weblogic, WebSphere, Jenkins, Gitlab, Redis, RabbitMQ等等

# 如何使用
- components中的脚本文件可以不依赖SmartCMP平台使用
- components打包后只能用于SmartCMP平台

# 开发说明
## 1. 类型定义
```text
# 软件基本类型
   resource.software
   resource.software.web
   resource.software.app
   resource.software.bigdata
   resource.software.cache
   resource.software.mq
   resource.software.rds
# 可以基于以上类型定义新的子类型
   resource.software.web.apache
   resource.software.web.tomcat
   resource.software.mq.rabbitmq
   resource.software.rds.mysql
```
                     
## 2. 组件组成部分
```text
software-components/resource.software.rds.sql_server2012
├── main.json                # 组件的元数据定义
├── scripts                  # 组件的脚本目录
│   └── Install.ps1    # 组件脚本，可以包含多级目录
├── scripts.json             # 脚本描述信息定义
└── types                    
    └── main.yaml            # 组件的属性和生命周期定义
```   
## 3. 脚本编写规范
### Python 脚本示例
```python
# Python 2/3，根据目标执行系统来决定
import os
from pysdx import ctx
 
 
# 如果create表单里定义了download_url这个参数，使用下面两种方式都可以获取
# 1. 使用ctx获取，全局的操作脚本都可以使用
resource_config = ctx.node.properties['resource_config']
connection_config = ctx.node.properties['connection_config']
download_url = resource_config.get('download_url')
 
# 2. 使用环境变量方式获取，仅Create操作的脚本可以使用
download_url = os.environ.get('download_url')
 
# 输出调试日志到操作历史
ctx.logger.info("Resource config: {0}".format(resource_config))
ctx.logger.info("Connection config: {0}".format(connection_config))
# 更新runtime properties
ctx.instance.runtime_properties['var'] = 'value'
ctx.instance.update()

```
### Shell 脚本示例
```shell
# 如果create表单里定义了download_url这个参数
# 使用如下方式获取参数
echo $(ctx node properties resource_config)
echo $(ctx node properties resource_config.download_url)
curl -LO $(ctx node properties resource_config.download_url)

# 或者直接通过环境变量的方式获取
download_url=$download_url
```
## 4. 表单编写规范
组件的定义，离不开自定义的申请表单，我们可以定义申请表单来控制申请组件服务时的一些变量填写

[表单示例](software-components/Sample-Software/sample_form.json)   

# 如何打包
使用zip工具完成独立的组件打包，打包不包含组件一级目录

举例：

resource.software.web.lamp 组件需要打包为 resource.software.web.lamp.zip，
zip包里不包含'resource.software.web.lamp'这一级目录

# 如何测试
打开 SmartCMP 控制台 -> 找到服务设计-组件库菜单 -> 点击导入 -> 选择打包的组件zip包 -> 保存并发布

# 如何贡献
欢迎提交PR

# 修改历史

# 如何获取帮助
欢迎提交Issue