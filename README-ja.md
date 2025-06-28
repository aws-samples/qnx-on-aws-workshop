# BlackBerry QNX on AWS ワークショップ <!-- omit in toc -->

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[English](README.md) | **日本語**

- [概要](#概要)
- [アーキテクチャ概要](#アーキテクチャ概要)
- [ファイル構成](#ファイル構成)
- [前提条件](#前提条件)
    - [AWS 環境](#aws-環境)
        - [AWS アカウント](#aws-アカウント)
        - [AWS 認証情報](#aws-認証情報)
        - [AWS リージョン](#aws-リージョン)
    - [クライアント PC](#クライアント-pc)
    - [QNX ソフトウェア](#qnx-ソフトウェア)
        - [myQNX アカウント と QNX 製品評価 ライセンス](#myqnx-アカウント-と-qnx-製品評価-ライセンス)
        - [QNX AMI サブスクリプション](#qnx-ami-サブスクリプション)
    - [GitHub リポジトリ](#github-リポジトリ)
- [手順](#手順)
- [セキュリティ](#セキュリティ)
- [ライセンス](#ライセンス)
- [参考資料](#参考資料)
    - [QNX 8.x](#qnx-8x)
    - [QNX 7.x](#qnx-7x)


## 概要

BlackBerry QNX on AWS ワークショップでは、AWS クラウド上での組み込みソフトウェア開発を簡単に始めることができます。このワークショップは、お客様が AWS 上での QNX® OS を使用した組み込みソフトウェア開発を迅速に理解できるよう、ハンズオンラボ体験を提供します。

2023年1月、BlackBerry Limited は、AWS Marketplace を通じて以下の QNX オペレーティングシステムの[一般提供開始を発表](https://www.blackberry.com/us/en/company/newsroom/press-releases/2023/blackberry-introduces-qnx-accelerate-announces-global-availability-of-blackberry-qnx-rtos-and-qnx-os-for-safety-in-aws-marketplace)しました。

* [QNX® Neutrino® Real Time Operating System (RTOS) 7.1](https://aws.amazon.com/marketplace/pp/prodview-wjqoq2mq7hrhc)
* [QNX® OS for Safety 2.2.3](https://aws.amazon.com/marketplace/pp/prodview-26pvihq76slfa)

2024年5月、BlackBerry は以下の QNX オペレーティングシステムの[提供開始を発表](https://www.edaway.com/2024/03/18/qnx-8-0-cloud/)しました。

* [QNX OS 8.0](https://aws.amazon.com/marketplace/pp/prodview-fyhziqwvrksrw)



BlackBerry® QNX® は、自動車、ロボティクス、航空宇宙、航空電子工学、エネルギー、医療などの業界において、ミッションクリティカルな組み込みシステムの構築に広く使用されています。

新しい QNX Amazon Machine Image (AMI) と AWS Graviton プロセッサ（AWS が開発した Arm ベースのプロセッサ）を搭載した Amazon EC2 インスタンスの組み合わせにより、AWS のお客様は、AWS クラウドの俊敏性、柔軟性、拡張性を活用して組み込みソフトウェア開発をサポートできます。


このリポジトリは、ワークショップパッケージとワークショップのベース環境を構築するためのクイック手順を提供します。詳細な手順については、[BlackBerry QNX on AWS workshop](https://catalog.workshops.aws/qnx-on-aws) を参照してください。


## アーキテクチャ概要

ワークショップでは、以下のアーキテクチャに基づいて AWS リソースをデプロイします。

<img src="docs/image/qnx-workshop-architecture-diagram.drawio.png" width="1000" alt="Architecture Diagram">


* AWS アカウント、ユーザー、リソース
    * ワークショップリソースは単一の AWS アカウントにデプロイされます。
    * AWS アカウント内の各ユーザーは一意のユーザー ID で認証されます。
    * ワークショップは各ユーザーに対して VPC、EC2 Ubuntu インスタンス、EC2 QNX インスタンスなどのリソースをデプロイします。
* QNX 開発ホスト
    * EC2 開発ホスト（EC2 インスタンスに QNX SDP がインストールされている）を選択した場合、各ユーザーは Session Manager を使用して SSM ポートフォワーディングで安全に接続を確立し、クライアント PC から Remote Desktop クライアントを使用して Ubuntu Linux にログインします。EC2 Ubuntu インスタンスの秘密鍵は Secrets Manager シークレットで安全に管理されます。
    * ローカル開発ホスト（クライアント PC に QNX SDP がインストールされている）を選択した場合、各ユーザーはクライアント PC にログインします。
* QNX ターゲット
    * EC2 QNX インスタンス（QNX ターゲット）は、AWS 上の分離された安全な VPC ネットワークにデプロイされます。
    * EC2 QNX ターゲットに安全にアクセスするため、各ユーザーはSession Managerを使用してSSMポートフォワーディングで安全に接続を確立し、SSHクライアントを使用して EC2 QNX インスタンスにログインします。EC2 QNX インスタンスの秘密鍵は Secrets Manager シークレットで安全に管理されます。
* CI パイプライン
    * ワークショップは、EC2 QNX インスタンスで継続的インテグレーション (CI) パイプラインを実行するための CodeBuild プロジェクト、CodePipeline パイプライン、VPC エンドポイントを作成します。
    * CodeBuild コンテナは、EC2 QNX インスタンスなどのCIパイプラインリソースをデプロイし、事前定義された CI タスクを実行します。CI タスクが完了すると、作成されたリソースを自動的に破棄します。


## ファイル構成

重要なファイルを以下に示します。

```shell
qnx-on-aws-workshop/
├── .gitignore                          # Git ignore設定
├── CODE_OF_CONDUCT.md                  # 行動規範ガイドライン
├── CONTRIBUTING.md                     # 貢献ガイドライン
├── LICENSE                             # ライセンスファイル
├── README-ja.md                        # READMEファイル (日本語)
├── README.md                           # READMEファイル (英語)
├── docs/                               # ドキュメントファイル
│   ├── INSTRUCTIONS-ja.md              # ワークショップ手順 (日本語)
│   ├── INSTRUCTIONS.md                 # ワークショップ手順 (英語)
│   └── image/                          # ドキュメント用画像ファイル
├── github-example-repo/                # GitHubリポジトリに保存されるCodeBuildファイル
│   ├── .gitignore                      # CIリポジトリ用Git ignore設定
│   ├── app/
│   │   └── run_command.sh              # サンプルCIアプリケーション
│   ├── arguments.txt                   # CIアプリケーションに渡される引数のリスト
│   ├── buildspec.yaml                  # CodeBuildのビルド仕様
│   ├── ec2-qnx.tf                      # CIパイプライン内のEC2 QNXインスタンス用Terraform設定
│   ├── main.tf                         # CIパイプライン用メインTerraform設定
│   ├── src/
│   │   └── get_primes.c                # サンプルCIアプリケーションソース
│   └── variables.tf                    # CIパイプライン用Terraform変数設定
├── simple-qnx-cockpit/                 # シンプルQNXコックピットアプリケーション
│   ├── .gitignore                      # コックピットアプリケーション用Git ignore設定
│   ├── Makefile                        # ビルド設定
│   ├── README-ja.md                    # READMEファイル (日本語)
│   ├── README.md                       # READMEファイル (英語)
│   └── cockpit.cpp                     # メインコックピットアプリケーションソースコード
└── terraform/                          # ベース環境用Terraform設定
    ├── .tool-versions                  # ツールバージョン仕様
    ├── codex.tf                        # AWS開発者ツール用Terraform設定
    ├── ec2-qnx.tf                      # EC2 QNXインスタンス用Terraform設定
    ├── ec2-ubuntu.tf                   # EC2 Ubuntuインスタンス用Terraform設定
    ├── keys_and_secrets.tf             # EC2キーペア、シークレット、KMS用Terraform設定
    ├── main.tf                         # ベース環境用メインTerraform設定
    ├── output.tf                       # 出力値用Terraform設定
    ├── script/
    │   └── user_data_script_ubuntu.sh  # EC2 Ubuntuインスタンス用ユーザーデータスクリプト
    ├── terraform.tfvars.template       # Terraform変数ファイルテンプレート
    ├── variables.tf                    # 入力変数用Terraform設定
    └── vpc.tf                          # VPC用Terraform設定
```


## 前提条件

### AWS 環境

#### AWS アカウント

ワークショップでは、お客様自身の AWS アカウントを使用します。管理者アクセス権限を持つ AWS アカウントをまだお持ちでない場合は、[こちらをクリック](https://portal.aws.amazon.com/billing/signup#/start/email)してアカウントを作成してください。


#### AWS 認証情報

ワークショップでは、AWS アカウントで管理者権限を持つユーザーとして実行します。管理者権限を持つユーザーのAWS認証情報にアクセスできることを確認してください。


#### AWS リージョン

ワークショップは以下の AWS リージョンで実行するように設計されています。

| AWS リージョン名           | リージョンコード    |
| :----------------------- | :--------------- |
| Asia Pacific (Tokyo)     | `ap-northeast-1` |
| Asia Pacific (Seoul)     | `ap-northeast-2` |
| Asia Pacific (Singapore) | `ap-southeast-1` |
| Europe (Frankfurt)       | `eu-central-1`   |
| Europe (Ireland)         | `eu-west-1`      |
| US East (N. Virginia)    | `us-east-1`      |
| US West (Oregon)         | `us-west-2`      |


### クライアント PC

クライアント PC 環境では以下が使用されます。

* macOS または Linux または Windows OS
* Mozilla Firefox または Google Chrome
* SSH クライアント
* Remote Desktop クライアント
* AWS CLI version 2
* AWS CLI Session Manager プラグイン
* Terraform version 1.9.3以上

### QNX ソフトウェア

#### myQNX アカウント と QNX 製品評価 ライセンス

ワークショップ では、参加者は [myQNX](https://blackberry.qnx.com/en) アカウントを登録する必要があります。ワークショップ前にアカウントを登録し、QNX SDP 8.0 の評価ライセンスを申請してください。ライセンス取得に時間がかかる場合があるため、事前にライセンスを申請してください。myQNX アカウントの登録と評価ライセンスの申請については、以下のリンクを参照してください。

* [myQNX アカウント登録](https://www.qnx.com/account/login.html?logout=1#showcreate)
* [評価ライセンス申請](https://www.qnx.com/products/evaluation/)

ワークショップでは、評価ライセンスで以下の QNX 製品を使用します。

* QNX® Software Development Platform (SDP) 8.0
* QNX® Momentics® Integrated Development Environment (IDE)
* QNX® Software Center

#### QNX AMI サブスクリプション

ワークショップでは、AWS Marketplace サブスクリプションで以下の QNX 製品を使用します。

* QNX® OS 8.0

### GitHub リポジトリ

ワークショップでは、CI/CD に GitHub リポジトリを使用します。ワークショップ前に GitHub ユーザーとリポジトリを作成してください。


## 手順

詳細な手順については、[手順](docs/INSTRUCTIONS-ja.md) を参照してください。

## セキュリティ

詳細については、[CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) を参照してください。


## ライセンス

このライブラリは MIT-0 ライセンスの下でライセンスされています。[LICENSE](LICENSE) ファイルを参照してください。


## 参考資料

### QNX 8.x

* [AWS Marketplace: QNX OS 8.0](https://aws.amazon.com/marketplace/pp/prodview-fyhziqwvrksrw)
* [QNX Amazon Machine Image Technotes](https://www.qnx.com/developers/docs/8.0/com.qnx.doc.qnxcloud.ami/topic/about_ami.html)
* [QNX Momentics IDE User's Guide](https://www.qnx.com/developers/docs/8.0/com.qnx.doc.ide.userguide/topic/about.html)
* [QNX® Software Development Platform 8.0](https://www.qnx.com/developers/docs/8.0/com.qnx.doc.qnxsdp.nav/topic/bookset.html)


### QNX 7.x

* [AWS Marketplace - QNX Neutrino RTOS 7.1](https://aws.amazon.com/marketplace/pp/prodview-wjqoq2mq7hrhc)
* [AWS Marketplace - QNX OS for Safety 2.2.3](https://aws.amazon.com/marketplace/pp/prodview-26pvihq76slfa)
* [AWS Blog "Accelerate embedded software development using QNX® Neutrino® OS on Amazon EC2 Graviton"(English)](https://aws.amazon.com/jp/blogs/industries/accelerate-embedded-software-development-using-qnx-os-on-amazon-ec2-graviton/)
* [AWS Blog "Accelerate embedded software development using QNX® Neutrino® OS on Amazon EC2 Graviton"(Japanese)](https://aws.amazon.com/jp/blogs/news/accelerate-embedded-software-development-using-qnx-os-on-amazon-ec2-graviton/)
* [Getting Started with QNX in the Cloud: QNX Amazon Machine Image 1.0.1](https://get.qnx.com/download/feature.html?programid=70060)
* [Create myQNX account](https://www.qnx.com/account/login.html?logout=1#showcreate)
* [QNX SDP 7.1 30-day Evaluation](https://www.qnx.com/products/evaluation/)
* [QNX Software Center 2.0](http://www.qnx.com/download/group.html?programid=29178)
* [QNX Software Center 2.0: Installation Notes](http://www.qnx.com/developers/articles/inst_6963_1.html)
* [QNX Momentics IDE User's Guide](https://www.qnx.com/developers/docs/7.1/#com.qnx.doc.ide.userguide/topic/about.html)
* [QNX Software Development Platform](https://www.qnx.com/developers/docs/7.1/#com.qnx.doc.qnxsdp.nav/topic/bookset.html)
* [QNX Training | Embedded Development and Product Training | BlackBerry QNX](https://blackberry.qnx.com/en/services/training)
