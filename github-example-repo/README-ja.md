# CI/CD セットアップガイド - QNX on AWS ワークショップ <!-- omit in toc -->

[English](README.md) | **日本語**

このガイドでは、AWS CodeBuild/CodePipeline または GitHub Actions を使用して、QNX on AWS ワークショップの継続的インテグレーション/継続的デプロイメント（CI/CD）をセットアップする方法を説明します。

## 目次

- [目次](#目次)
- [概要](#概要)
- [前提条件](#前提条件)
- [CI/CD プロバイダーの選択](#cicd-プロバイダーの選択)
- [オプション1: GitHub Actions セットアップ（デフォルト）](#オプション1-github-actions-セットアップデフォルト)
   - [1. Terraform変数の設定](#1-terraform変数の設定)
   - [2. GitHub認証のセットアップ](#2-github認証のセットアップ)
   - [3. インフラストラクチャのデプロイ](#3-インフラストラクチャのデプロイ)
   - [4. 自動リポジトリ変数セットアップ ✨](#4-自動リポジトリ変数セットアップ-)
   - [5. リポジトリファイルのコピー](#5-リポジトリファイルのコピー)
   - [6. ワークフローの監視](#6-ワークフローの監視)
- [オプション2: AWS CodeBuild/CodePipeline セットアップ](#オプション2-aws-codebuildcodepipeline-セットアップ)
   - [1. Terraform変数の設定](#1-terraform変数の設定-1)
   - [2. インフラストラクチャのデプロイ](#2-インフラストラクチャのデプロイ)
   - [3. GitHub接続の設定](#3-github接続の設定)
   - [4. リポジトリファイルのコピー](#4-リポジトリファイルのコピー)
   - [5. パイプラインの監視](#5-パイプラインの監視)
- [リポジトリ構造](#リポジトリ構造)
- [CI/CD ワークフロー](#cicd-ワークフロー)
   - [ワークフローのカスタマイズ](#ワークフローのカスタマイズ)
      - [アプリケーションロジックの変更](#アプリケーションロジックの変更)
      - [インスタンス数の調整](#インスタンス数の調整)
      - [アプリケーション引数の変更](#アプリケーション引数の変更)
- [プロバイダー間の切り替え](#プロバイダー間の切り替え)
- [比較](#比較)
- [トラブルシューティング](#トラブルシューティング)
   - [よくある問題](#よくある問題)
      - [CodeBuildの問題](#codebuildの問題)
      - [GitHub Actionsの問題](#github-actionsの問題)
   - [デバッグ手順](#デバッグ手順)
   - [セキュリティ考慮事項](#セキュリティ考慮事項)
      - [CodeBuild](#codebuild)
      - [GitHub Actions](#github-actions)
- [次のステップ](#次のステップ)


## 概要

ワークショップでは2つのCI/CDアプローチをサポートしています：

1. **AWS CodeBuild/CodePipeline**: 自動GitHub統合を持つフルマネージドAWSサービス
2. **GitHub Actions**: AWS OIDC認証を使用したGitHubネイティブCI/CD

両方のアプローチ共通機能：
- テスト用の一時的なQNX EC2インスタンスをデプロイ
- QNXターゲット上でアプリケーションを実行
- 完了後にリソースを自動的にクリーンアップ
- 同じTerraformインフラストラクチャコードを使用

## 前提条件

CI/CDをセットアップする前に、以下を確認してください：

1. **Terraformを使用してベースワークショップ環境をデプロイ済み**
2. **カスタムQNX AMIを作成済み**（メインワークショップ手順を参照）
3. **適切な権限を持つGitHubリポジトリ**
4. **管理者アクセス権を持つAWS認証情報**

## CI/CD プロバイダーの選択

CI/CDプロバイダーはTerraform変数で設定します。`terraform.tfvars`ファイルで`ci_cd_provider`を設定してください：

```hcl
# CI/CDプロバイダーを選択
ci_cd_provider = "github-actions"   # GitHub Actionsを使用（デフォルト）
# ci_cd_provider = "codebuild"      # AWS CodeBuild/CodePipelineを使用
```

## オプション1: GitHub Actions セットアップ（デフォルト）

### 1. Terraform変数の設定

`terraform/terraform.tfvars`ファイルで以下を設定：

```hcl
# CI/CD設定
ci_cd_provider = "github-actions"

# GitHub設定
github_user = "your-github-username"
github_repo = "your-repository-name"
```

### 2. GitHub認証のセットアップ

**GitHub Personal Access Tokenの作成：**

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** に移動
2. **Generate new token (classic)** をクリック
3. 説明的な名前を付けます（例：「QNX Workshop Terraform」）
4. **repo** スコープを選択（プライベートリポジトリの完全制御）
5. **Generate token** をクリックしてトークンをコピー

**環境変数としてトークンを設定（推奨）：**
```bash
export GITHUB_TOKEN="your_github_personal_access_token_here"
```

### 3. インフラストラクチャのデプロイ

```bash
cd terraform/
terraform plan
terraform apply --auto-approve
```

### 4. 自動リポジトリ変数セットアップ ✨

**手動セットアップは不要です！** Terraformが必要なGitHubリポジトリ変数を自動的に作成します：

- `AWS_REGION` - AWSリージョン
- `AWS_ROLE_ARN` - OIDC認証用IAMロールARN
- `BUILD_PROJECT_NAME` - ビルドプロジェクト名
- `QNX_CUSTOM_AMI_ID` - カスタムQNX AMI ID
- `VPC_ID` - TerraformからのVPC ID
- `PRIVATE_SUBNET_ID` - プライベートサブネットID
- `VPC_CIDR_BLOCK` - VPC CIDRブロック
- `KEY_PAIR_NAME` - EC2キーペア名
- `PRIVATE_KEY_SECRET_ID` - Secrets ManagerシークレットID
- `KMS_KEY_ID` - KMSキーID
- `TF_VERSION` - Terraformバージョン
- `TF_BACKEND_S3` - Terraform状態用S3バケット

変数が作成されたことを確認するには：**Repository** → **Settings** → **Secrets and variables** → **Actions** → **Variables** タブをチェック

### 5. リポジトリファイルのコピー

```bash
# Terraformアウトプットからリポジトリ情報を取得
REPO_URL=$(terraform output -raw github_repository_url)
REPO_NAME=$(terraform output -raw github_repository_name)

# リポジトリをクローン
cd ~
git clone ${REPO_URL}
cd ./${REPO_NAME}

# ワークショップCIファイルをコピー（.githubディレクトリを含む）
cp -a <WORKSHOP_DIR>/github-example-repo/* ./
cp -a <WORKSHOP_DIR>/github-example-repo/.github ./

# コミットしてプッシュ
git add -A
git commit -m "Add GitHub Actions CI/CD configuration"
git push origin main
```

### 6. ワークフローの監視

1. GitHubリポジトリに移動
2. **Actions** タブをクリック
3. 「QNX CI Pipeline」ワークフローの実行を監視

## オプション2: AWS CodeBuild/CodePipeline セットアップ

### 1. Terraform変数の設定

`terraform/terraform.tfvars`ファイルで以下を設定：

```hcl
# CI/CD設定
ci_cd_provider = "codebuild"

# GitHub設定
github_user = "your-github-username"
github_repo = "your-repository-name"
```

### 2. インフラストラクチャのデプロイ

```bash
cd terraform/
terraform plan
terraform apply --auto-approve
```

### 3. GitHub接続の設定

AWS CodePipelineがGitHubリポジトリに接続できるようにするため、接続を手動で更新する必要があります。

1. AWS Developer Toolsコンソールで **Settings** → **Connections** に移動
2. Terraformデプロイの一部として作成された接続を選択（例：`qnx-on-aws-ws-xx`）
3. **Update pending connection** をクリック
4. **Install a new app** をクリック
5. GitHubページの手順に従ってAWS Connector for GitHubをインストール
6. 接続ステータスが `Available` になることを確認

### 4. リポジトリファイルのコピー

```bash
# Terraformアウトプットからリポジトリ情報を取得
REPO_URL=$(terraform output -raw github_repository_url)
REPO_NAME=$(terraform output -raw github_repository_name)

# リポジトリをクローン
cd ~
git clone ${REPO_URL}
cd ./${REPO_NAME}

# ワークショップCIファイルをコピー
cp -a <WORKSHOP_DIR>/github-example-repo/* ./

# コミットしてプッシュ
git add -A
git commit -m "Add CodeBuild CI/CD configuration"
git push origin main
```

### 5. パイプラインの監視

1. AWSリージョンの [CodePipeline console](https://console.aws.amazon.com/codesuite/codepipeline/pipelines) に移動
2. パイプライン名をクリック（例：`qnx-on-aws-ws-01`）
3. 詳細な進行状況を確認

## リポジトリ構造

CI/CDセットアップ後のリポジトリ構造：

```
your-repository/
├── .github/                    # GitHub Actions設定（GitHub Actionsの場合のみ）
│   └── workflows/
│       └── qnx-ci.yml         # GitHub Actionsワークフロー
├── app/
│   └── run_command.sh         # アプリケーション実行スクリプト
├── src/
│   └── get_primes.c           # サンプルCアプリケーション
├── arguments.txt              # アプリケーション引数
├── buildspec.yaml             # CodeBuildビルド仕様
├── main.tf                    # メインTerraform設定
├── variables.tf               # Terraform変数
└── ec2-qnx.tf                 # EC2 QNXインスタンス設定
```

## CI/CD ワークフロー

両方のCI/CDオプションは同じワークフローに従います：

1. **トリガー**: コードがメインブランチにプッシュされる
2. **インフラストラクチャ**: 一時的なQNX EC2インスタンスをデプロイ
3. **実行**: QNXターゲット上でアプリケーションを実行
4. **クリーンアップ**: すべてのリソースを自動的に削除

### ワークフローのカスタマイズ

#### アプリケーションロジックの変更

`app/run_command.sh`を編集してQNXインスタンス上で実行する内容をカスタマイズ：

```bash
#!/bin/bash
# ここにカスタムアプリケーションロジックを追加
echo "引数 $1 でQNX上で実行中"

# 例：Cアプリケーションのコンパイルと実行
gcc -o /tmp/get_primes /root/src/get_primes.c
/tmp/get_primes $1
```

#### インスタンス数の調整

以下の`INSTANCE_COUNT`変数を変更：
- `buildspec.yaml`（CodeBuildの場合）
- `.github/workflows/qnx-ci.yml`（GitHub Actionsの場合）

#### アプリケーション引数の変更

`arguments.txt`を編集して各インスタンスに異なる引数を提供：

```
1000
2000
3000
```

## プロバイダー間の切り替え

GitHub ActionsとCodeBuildを切り替えるには：

1. **Terraform設定の更新**
   ```bash
   # terraform.tfvarsを編集
   ci_cd_provider = "codebuild"        # または "github-actions"（デフォルト）
   ```

2. **変更の適用**
   ```bash
   terraform plan
   terraform apply
   ```

3. **リポジトリ設定の更新**
   - GitHub Actionsの場合：リポジトリ変数をセットアップ（デフォルト）
   - CodeBuildの場合：AWSコンソールでGitHub接続を設定

## 比較

| 機能 | GitHub Actions | CodeBuild/CodePipeline |
|------|----------------|------------------------|
| **セットアップの複雑さ** | 低（OIDC認証） | 中（GitHub接続が必要） |
| **トリガー** | ネイティブGitHubトリガー | CodePipeline経由のGitHubウェブフック |
| **設定** | `.github/workflows/qnx-ci.yml` | `buildspec.yaml` |
| **監視** | GitHub Actions UI | AWSコンソール（CodePipeline/CodeBuild） |
| **コスト** | GitHub Actions分数 | AWS CodeBuild料金 |
| **統合** | ネイティブGitHub統合 | 深いAWS統合 |
| **シークレット管理** | リポジトリ変数 | 環境変数 |
| **VPCサポート** | なし（GitHub-hostedランナー） | あり（VPC内のCodeBuild） |
| **デフォルト選択** | ✓ 推奨 | 代替案 |

## トラブルシューティング

### よくある問題

#### CodeBuildの問題

1. **接続が利用できない**：GitHub接続が適切に設定されていることを確認
2. **権限が拒否された**：CodeBuild IAMロールの権限を確認
3. **Terraformエラー**：すべての環境変数が正しく設定されていることを確認

#### GitHub Actionsの問題

1. **OIDC認証が失敗**：AWS_ROLE_ARNとリポジトリ設定を確認
2. **変数が見つからない**：必要なリポジトリ変数がすべて設定されていることを確認
3. **Terraformバックエンドエラー**：S3バケットの権限と設定を確認

### デバッグ手順

1. **Terraformアウトプットを確認**：
   ```bash
   terraform output ci_environment_variables
   ```

2. **AWS認証情報を確認**：
   ```bash
   aws sts get-caller-identity
   ```

3. **リソースステータスを確認**：
   ```bash
   # CodeBuildの場合
   aws codebuild list-projects
   aws codepipeline list-pipelines
   
   # GitHub Actionsの場合
   # GitHubリポジトリのActionsタブを確認
   ```

### セキュリティ考慮事項

#### CodeBuild
- 制御されたネットワークアクセスでVPC内で実行
- AWSサービス認証にIAMロールを使用
- KMS暗号化でCloudWatchにログを保存

#### GitHub Actions
- セキュアなAWS認証にOIDCを使用（長期間有効な認証情報不要）
- GitHub-hostedランナーで実行（VPC外）
- リポジトリ変数はリポジトリコラボレーターに表示

両方のオプション共通：
- プライベートキーはAWS Secrets Managerに安全に保存
- 実行ごとに一時的なQNXインスタンスを作成・削除
- S3状態バケットはKMSで暗号化
- 最小権限のIAM権限

## 次のステップ

CI/CDセットアップが成功した後：

1. 特定のユースケースに合わせてアプリケーションロジックをカスタマイズ
2. より高度なテストシナリオを追加
3. 既存の開発ワークフローと統合
4. ビルドステータスの通知を追加することを検討

より高度な設定とトラブルシューティングについては、メインワークショップドキュメントを参照してください。

