#!/bin/bash
# @Author: Alan Huang
# @Date:   2020-12-26 09:56:57
# @Last Modified by:   Alan Huang
# @Last Modified time: 2020-12-26 11:06:31
# @E-mail: cmrhyq@163.com
# 构架xxl-job 的executor docker镜像
# ！！！若要构建admin的镜像请修改dockerfile和脚本

VERSION=$1

docker build -t xxl-job-executor:${VERSION} .
