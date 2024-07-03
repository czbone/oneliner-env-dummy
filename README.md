# 1行で環境構築するスクリプトのテスト

Ansibleで環境構築するスクリプトの起動シェルをテストします。
サーバに`root`ログインし１行のコマンドを実行するとテストを開始します。

## 対象OS

- Ubuntu20
- Ubuntu22

## ライセンス

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

# 内容
Ansible起動までをテストします。

# 使い方
新規にOSをインストールしたサーバに`root`でログインし、以下の１行のコマンドをそのままコピーして実行します。

### 実行コマンド
```
curl https://raw.githubusercontent.com/czbone/oneliner-env-dummy/master/test/build_lemp.sh | bash
```
