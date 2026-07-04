# MenuBarTimer

macOSのメニューバーに常駐するシンプルなタイマーアプリです。

## 機能

- メニューバーのタイマーアイコンから操作画面を表示
- タイマー時間を「時間」「分」「秒」で個別に設定
- 開始後はメニューバーのアイコン横に残り時間を表示
- 半透明のガラス調UI
- タイマー完了時に最大30秒間、音を繰り返し再生
- 完了後に「音を止める」ボタンで再生を停止

## 起動

```sh
cd "/Users/k22125kk/Documents/New project/MenuBarTimer"
swift run MenuBarTimer
```

起動するとDockには表示されず、メニューバーにタイマーアイコンが出ます。

## `.app`として作成

```sh
cd "/Users/k22125kk/Documents/New project/MenuBarTimer"
./scripts/build_app_bundle.sh
```

アプリ本体は `MenuBarTimer/build/MenuBarTimer.app` に作成されます。これは動作確認用のビルド成果物です。普段使う場合は次の「アプリ一覧に追加」を使ってください。

## アプリ一覧に追加

```sh
cd "/Users/k22125kk/Documents/New project/MenuBarTimer"
./scripts/install_to_applications.sh
open "$HOME/Applications"
```

`~/Applications/MenuBarTimer.app` にインストールされ、Launchpadやアプリ一覧から起動しやすくなります。
