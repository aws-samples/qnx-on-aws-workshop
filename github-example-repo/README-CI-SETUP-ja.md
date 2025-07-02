# CI/CD セットアップ手順

[English](README-CI-SETUP.md) | **日本語**

このリポジトリは、CI/CDにAWS CodeBuild/CodePipelineとGitHub Actionsの両方をサポートしています。ニーズに最適なオプションを選択してください。

## CI/CDプロバイダーの選択

CI/CDプロバイダーはTerraform変数で設定します。`terraform.tfvars`ファイルで`ci_cd_provider`を設定してください：

- `"codebuild"` - AWS CodeBuildとCodePipelineを使用（デフォルト）
- `"github-actions"` - GitHub Actionsを使用

## オプション1: AWS CodeBuild/CodePipeline（デフォルト）

### 前提条件
1. 管理者権限を持つAWSアカウント
2. GitHubリポジトリ
3. `ci_cd_provider = "codebuild"`でデプロイされたTerraform

### セットアップ手順

1. **インフラストラクチャのデプロイ**
   ```bash
   cd terraform/
   # terraform.tfvarsでci_cd_provider = "codebuild"を設定
   terraform apply
   ```

2. **GitHub接続の設定**
   - AWS Developer Toolsコンソールの**設定** > **接続**に移動
   - Terraformで作成された接続を選択（例：`qnx-on-aws-ws-xx`）
   - **保留中の接続を更新**をクリック
   - AWS Connector for GitHubをインストールする手順に従う
   - リポジトリへの接続を承認

3. **リポジトリの準備**
   ```bash
   # GitHubリポジトリをクローン
   git clone https://github.com/your-username/your-repo.git
   cd your-repo
   
   # ワークショップファイルをコピー
   cp -a /path/to/qnx-on-aws-workshop/github-example-repo/* ./
   
   # コミットしてプッシュ
   git add -A
   git commit -m "Add QNX CI/CD pipeline"
   git push origin main
   ```

4. **パイプラインの監視**
   - [CodePipelineコンソール](https://console.aws.amazon.com/codesuite/codepipeline/pipelines)に移動
   - パイプライン名をクリック（例：`qnx-on-aws-ws-xx`）
   - パイプラインの実行を監視

### 設定ファイル
- `buildspec.yaml` - CodeBuildビルド仕様
- TerraformによるAWSリソース管理

## オプション2: GitHub Actions

### 前提条件
1. 管理者権限を持つAWSアカウント
2. Actionsが有効なGitHubリポジトリ
3. `ci_cd_provider = "github-actions"`でデプロイされたTerraform

### セットアップ手順

1. **インフラストラクチャのデプロイ**
   ```bash
   cd terraform/
   # terraform.tfvarsでci_cd_provider = "github-actions"を設定
   terraform apply
   ```

2. **設定値の取得**
   ```bash
   terraform output ci_environment_variables
   ```

3. **GitHubリポジトリ変数の設定**
   
   GitHubリポジトリ → **Settings** → **Secrets and variables** → **Actions** → **Variables**タブに移動
   
   以下の**リポジトリ変数**を追加：

   | 変数名 | 説明 | 値の取得方法 |
   |--------|------|-------------|
   | `AWS_REGION` | AWSリージョン | `terraform output aws_region` |
   | `AWS_ROLE_ARN` | GitHub Actions IAMロールARN | `terraform output github_actions_role_arn` |
   | `BUILD_PROJECT_NAME` | ビルドプロジェクト名 | あなたの`build_project_name`変数 |
   | `QNX_CUSTOM_AMI_ID` | カスタムQNX AMI ID | あなたの`qnx_custom_ami_id`変数 |
   | `VPC_ID` | VPC ID | Terraform出力から |
   | `PRIVATE_SUBNET_ID` | プライベートサブネットID | Terraform出力から |
   | `VPC_CIDR_BLOCK` | VPC CIDRブロック | Terraform出力から |
   | `KEY_PAIR_NAME` | EC2キーペア名 | Terraform出力から |
   | `PRIVATE_KEY_SECRET_ID` | Secrets Managerシークレット ID | Terraform出力から |
   | `KMS_KEY_ID` | KMSキーID | Terraform出力から |
   | `TF_VERSION` | Terraformバージョン | あなたの`terraform_version`変数 |
   | `TF_BACKEND_S3` | Terraform状態用S3バケット | Terraform出力から |

4. **リポジトリの準備**
   ```bash
   # GitHubリポジトリをクローン
   git clone https://github.com/your-username/your-repo.git
   cd your-repo
   
   # ワークショップファイルをコピー（.github/workflows/を含む）
   cp -a /path/to/qnx-on-aws-workshop/github-example-repo/* ./
   cp -a /path/to/qnx-on-aws-workshop/github-example-repo/.github ./
   
   # コミットしてプッシュ
   git add -A
   git commit -m "Add QNX GitHub Actions CI/CD pipeline"
   git push origin main
   ```

5. **ワークフローの監視**
   - GitHubリポジトリ → **Actions**タブに移動
   - ワークフロー実行をクリックして詳細ログを確認

### 設定ファイル
- `.github/workflows/qnx-ci.yml` - GitHub Actionsワークフロー
- 設定用のリポジトリ変数

## CI/CDプロバイダーの切り替え

CodeBuildとGitHub Actionsを切り替えるには：

1. **Terraform設定の更新**
   ```bash
   # terraform.tfvarsを編集
   ci_cd_provider = "github-actions"  # または "codebuild"
   ```

2. **変更の適用**
   ```bash
   terraform plan
   terraform apply
   ```

3. **リポジトリの更新**
   - CodeBuildの場合：`buildspec.yaml`が存在することを確認
   - GitHub Actionsの場合：`.github/workflows/qnx-ci.yml`が存在し、変数が設定されていることを確認

## 比較

| 機能 | CodeBuild/CodePipeline | GitHub Actions |
|------|------------------------|----------------|
| **セットアップの複雑さ** | 中程度（GitHub接続が必要） | 低（OIDC認証） |
| **トリガー** | CodePipeline経由のGitHub webhook | ネイティブGitHubトリガー |
| **設定** | `buildspec.yaml` | `.github/workflows/qnx-ci.yml` |
| **監視** | AWSコンソール（CodePipeline/CodeBuild） | GitHub Actions UI |
| **コスト** | AWS CodeBuild料金 | GitHub Actions分数 |
| **統合** | 深いAWS統合 | ネイティブGitHub統合 |
| **シークレット管理** | 環境変数 | リポジトリ変数 |
| **VPCサポート** | あり（VPC内のCodeBuild） | なし（GitHub ホストランナー） |

## トラブルシューティング

### CodeBuildの問題
1. **接続失敗**：AWSコンソールでGitHub接続を更新
2. **ビルド失敗**：CodeBuildコンソールでCloudWatchログを確認
3. **権限拒否**：IAMロールとポリシーを確認

### GitHub Actionsの問題
1. **認証失敗**：`AWS_ROLE_ARN`とOIDCセットアップを確認
2. **変数が見つからない**：リポジトリ変数の設定を確認
3. **Terraformバックエンドエラー**：S3バケットの権限を確認

### 共通の問題
1. **SSH接続失敗**：Secrets Managerの秘密鍵を確認
2. **QNXインスタンスが見つからない**：カスタムAMI IDとインスタンス設定を確認
3. **リソース作成失敗**：AWS権限とクォータを確認

## セキュリティ考慮事項

### CodeBuild
- 制御されたネットワークアクセスでVPC内で実行
- AWSサービス認証にIAMロールを使用
- KMS暗号化でCloudWatchにログを保存

### GitHub Actions
- 安全なAWS認証にOIDCを使用（長期間の認証情報なし）
- GitHubホストランナーで実行（VPC外）
- リポジトリ変数はリポジトリコラボレーターに表示

両方のオプション：
- 秘密鍵はAWS Secrets Managerに安全に保存
- 実行ごとに一時的なQNXインスタンスを作成・破棄
- S3状態バケットはKMSで暗号化
- 最小権限のIAM権限
