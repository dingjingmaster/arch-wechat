#!/bin/bash

set -e -u

app_version="2.0.0"
work_dir=$(cd $(realpath -- $(dirname $0)); pwd)
app_list=('ukui-wechat')
app_name="ukui-wechat"
yay_name="ukui-wechat"
sha256sumsStr=""

############################################## 常用函數 ###############################################
# 输出信息
_msg_info()
{
    local _msg="${1}"
    if [[ ${app_name} == '' ]]; then
        printf '\033[32m信息: %s\033[0m\n' "${_msg}" | sed ':label;N;s/\n/ /g;b label' | sed 's/[ ][ ]*/ /g'
    else
        printf '\033[32m[%s] 信息: %s\033[0m\n' "${app_name}" "${_msg}" | sed ':label;N;s/\n/ /g;b label' | sed 's/[ ][ ]*/ /g'
    fi
}

# 输出信息
_msg_info_pure()
{
    local _msg="${1}"
    if [[ ${app_name} == '' ]]; then
        printf '\033[32m信息: %s\033[0m\n' "${_msg}"
    else
        printf '\033[32m[%s] 信息: %s\033[0m\n' "${app_name}" "${_msg}"
    fi
}

# 输出警告
_msg_warning()
{
    local _msg="${1}"
    if [[ ${app_name} == '' ]]; then
        printf '\033[33m警告: %s\033[0m\n' "${_msg}" >&2
    else
        printf '\033[33m[%s] 警告: %s\033[0m\n' "${app_name}" "${_msg}" >&2
    fi
}

# 输出错误
_msg_error()
{
    local _msg="${1}"
    local _error="${2}"
    if [[ ${app_name} == '' ]]; then
        printf '\033[31m错误: %s\033[0m\n' "${_msg}" >&2
    else
        printf '\033[31m[%s] 错误: %s\033[0m\n' "${app_name}" "${_msg}" >&2
    fi

    if (( _error > 0 )); then
        exit "${_error}"
    fi
}

# 开始下载release包并生成hash
_download_package()
{
    cd ${work_dir}
    wget "https://github.com/dingjingmaster/arch-wechat/archive/${app_version}.tar.gz"
    sha256sumsStr=$(sha256sum -- ${app_version}.tar.gz | awk '{print $1}')
    echo ${sha256sumsStr}
}

# 创建PKGBUILD
_pkgbuild()
{
cat > PKGBUILD << END_TEXT
# Maintainer: dingjing <dingjing[at]live[dot]cn>
# Cloud Server
_server=cpx51
pkgbase=ukui-wechat
pkgname=('ukui-wechat')
pkgver=${app_version}
pkgrel=1
arch=('x86_64')
url="https://github.com/dingjingmaster/arch-wechat"
license=('GPL')
depends=(
    'gtk2'
    'gvfs'
    'glib2'
    'libxss'
    'libxtst'
    'alsa-lib'
    'libnotify'
    'xdg-utils'
    'pulseaudio'
)
makedepends=(
    'git'
)
source=(
    "https://github.com/dingjingmaster/arch-wechat/archive/\${pkgver}.tar.gz"
)
sha256sums=(
    "${sha256sumsStr}"
)
    
prepare() {
    msg "prepare"
}
    
build() {
    msg "start build..."
}
package_ukui-wechat() {
    msg "\${pkgname} package"
    cd "\${srcdir}/arch-wechat-\${pkgver}"
    install -d -Dm755                                                               "\${pkgdir}/usr/lib"
    install -d -Dm755                                                               "\${pkgdir}/usr/bin"
    install -d -Dm755                                                               "\${pkgdir}/usr/share/doc"
    install -d -Dm755                                                               "\${pkgdir}/usr/share/pixmaps"
    install -d -Dm755                                                               "\${pkgdir}/usr/share/applications"

    install -Dm755 wechat-debian-2.0/usr/lib/libnode.so                             "\${pkgdir}/usr/lib/libnode.so"
    install -Dm755 wechat-debian-2.0/usr/lib/libffmpeg.so                           "\${pkgdir}/usr/lib/libffmpeg.so"

    cp -ra wechat-debian-2.0/usr/lib/wechat                                         "\${pkgdir}/usr/lib/"
    cp -ra wechat-debian-2.0/usr/share/doc/wechat                                   "\${pkgdir}/usr/share/doc/"
    install -Dm755 wechat-debian-2.0/usr/bin/wechat                                 "\${pkgdir}/usr/bin/wechat"
    install -Dm644 wechat-debian-2.0/usr/share/pixmaps/wechat.png                   "\${pkgdir}/usr/share/pixmaps/wechat.png"
    install -Dm644 wechat-debian-2.0/usr/share/applications/wechat.desktop          "\${pkgdir}/usr/share/applications/wechat.desktop"
}
END_TEXT
}

# 清空中间文件
_clean()
{
    cd -- "${work_dir}"
    #_msg_info "rm -rf ${work_dir}/${app_version}.tar.gz"
    #rm -rf "${work_dir}/${app_version}.tar.gz"

    _msg_info "rm -rf ${work_dir}/src"
    rm -rf "${work_dir}/src"

    #_msg_info "rm -rf ${work_dir}/pkg"
    #rm -rf "${work_dir}/pkg"

    _msg_info "rm -rf ${work_dir}/PKGBUILD"
    rm -rf "${work_dir}/PKGBUILD"

    _msg_info "rm -rf ${work_dir}/.SRCINFO"
    rm -rf "${work_dir}/.SRCINFO"

    _msg_info "rm -rf ${work_dir}/ukui-wechat-*.pkg.tar.zst"
    rm -rf "${work_dir}/ukui-wechat-*.pkg.tar.zst"

    #_msg_info "rm -rf ${work_dir}/${yay_name}"
    #rm -rf "${work_dir}/${yay_name}"

    rm -rf "ukui-wechat-${app_version}-1-x86_64.pkg.tar.zst"
}

# 推送到 yay 仓库
_push_to_yay()
{
    _msg_info "git clone ssh://aur@aur.archlinux.org/ukui-wechat.git ${work_dir}/${yay_name}"
    git clone "ssh://aur@aur.archlinux.org/ukui-wechat.git" "${work_dir}/${yay_name}"

    cp ${work_dir}/LICENSE      "${work_dir}/${yay_name}/"
    cp ${work_dir}/PKGBUILD     "${work_dir}/${yay_name}/"
    cp ${work_dir}/README.md    "${work_dir}/${yay_name}/"
    cp ${work_dir}/.SRCINFO     "${work_dir}/${yay_name}/"

    cd -- "${work_dir}/${yay_name}"
    git add -A
    git commit -m "${yay_name} ${app_version}"
    git push -f
    cd -- "${work_dir}"
}


_main()
{
    if (( EUID == 0 ));then
        msg_error "${app_name}不可以 root 运行此脚本." 1
    fi

    _msg_info "开始清空上次安装的内容"
    _clean

    _msg_info "开始生成hash"
    _download_package

    _msg_info "开始生成PKGBUILD文件"
    _pkgbuild
    _msg_info "开始构建arch系安装包"
    makepkg -f
    makepkg --printsrcinfo > .SRCINFO
    #_push_to_yay

    #_clean
    _msg_info "一切完成!!!"
}

_main
