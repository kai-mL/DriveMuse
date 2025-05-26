# DriveMuse

観光地を探索できるiOSマップアプリケーション

## 概要

DriveMuseは、SwiftUIとMapKitを使用して構築された観光地探索アプリです。現在地周辺の観光スポットを検索し、詳細情報を表示することができます。

## 機能

- 📍 現在地の表示
- 🗺️ 周辺観光地の自動検索
- ⭐ 距離に基づく評価システム
- 📱 詳細情報の表示（電話番号、URL、住所）
- 🧭 マップアプリでの道案内

## アーキテクチャ

### ディレクトリ構成

```
DriveMuse/
├── Models/
│   └── POIAnnotation.swift        # POIアノテーションモデル
├── ViewModels/
│   └── MapViewModel.swift         # 地図とPOI検索のビジネスロジック
├── Views/
│   ├── TouristMapView.swift       # マップビューコンポーネント
│   └── PlaceDetailView.swift      # 詳細表示コンポーネント
├── Utils/
│   ├── Constants.swift            # 定数管理
│   └── LocationManager.swift      # 位置情報管理
└── ContentView.swift              # メインビュー
```

### 主要な改善点

#### 1. **責任の分離**
- 元々214行の単一ファイルを複数のファイルに分割
- Model、View、ViewModelの明確な分離
- 各クラスが単一責任を持つように設計

#### 2. **エラーハンドリング**
- 位置情報エラーの適切な処理
- 検索エラーの表示
- ユーザーフィードバックの向上

#### 3. **パフォーマンス最適化**
- デバウンス機能による検索の最適化
- Task/async-awaitを使用した非同期処理
- 重複検索の防止

#### 4. **アクセシビリティ**
- VoiceOverサポート
- 適切なアクセシビリティラベル
- ユーザビリティの向上

#### 5. **保守性の向上**
- 定数の一元管理
- 再利用可能なコンポーネント
- 型安全性の確保

## 技術スタック

- **フレームワーク**: SwiftUI, MapKit, CoreLocation
- **アーキテクチャ**: MVVM
- **非同期処理**: Swift Concurrency (async/await)
- **状態管理**: @StateObject, @ObservedObject

## 主要コンポーネント

### MapViewModel
地図とPOI検索のビジネスロジックを管理

- POI検索の実行
- 位置情報の管理
- エラーハンドリング
- 状態の管理

### TouristMapView
MKMapViewをSwiftUIで利用するためのラッパー

- マップの表示設定
- アノテーションの管理
- ユーザーインタラクションの処理

### PlaceDetailView
選択された場所の詳細情報を表示

- 場所の基本情報表示
- 連絡先情報の表示
- マップアプリとの連携

### LocationManager
位置情報の取得と管理

- 位置情報の許可リクエスト
- 現在地の取得
- エラーハンドリング

## セットアップ

### 1. プロジェクトのクローン
```bash
git clone [repository-url]
cd DriveMuse
```

### 2. APIキーの設定
1. `DriveMuse/Config/APIKeys.example.plist` を `APIKeys.plist` にコピー
```bash
cp DriveMuse/Config/APIKeys.example.plist DriveMuse/Config/APIKeys.plist
```

2. `APIKeys.plist` を開いて、実際のGemini APIキーを入力
```xml
<key>GEMINI_API_KEY</key>
<string>あなたのGemini APIキーをここに入力</string>
```

### 3. Gemini APIキーの取得方法
1. [Google AI Studio](https://aistudio.google.com/) にアクセス
2. 「Get API key」をクリック
3. 新しいAPIキーを作成
4. 作成されたキーをコピーして `APIKeys.plist` に貼り付け

### 4. ビルドと実行
1. Xcodeでプロジェクトを開く
2. 実機またはシミュレータでビルド・実行
3. 位置情報の利用許可を与える

### ⚠️ 重要な注意事項
- `APIKeys.plist` ファイルは `.gitignore` に含まれているため、Gitにコミットされません
- チーム開発の場合は、各開発者が個別にAPIキーを設定する必要があります
- 本番環境では、より安全な方法（環境変数、Keychain等）でAPIキーを管理することを推奨します

## 必要な権限

- 位置情報の利用許可（whenInUse）

## 今後の拡張可能性

- [ ] お気に入り機能
- [ ] ルート案内機能
- [ ] オフライン対応
- [ ] 多言語対応
- [ ] ユーザーレビュー機能
- [ ] 写真表示機能

## ライセンス

MIT License 