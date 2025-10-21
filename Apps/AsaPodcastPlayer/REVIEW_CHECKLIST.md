# レビュー指摘チェックリスト

- [x] `PodcastLibraryManager.loadSamplePodcasts()` が `createSampleEpisodes` で実際に存在しないファイルパスを `PodcastEpisode.filePath` に設定しているため、サンプルデータ環境で `AVAudioPlayer(contentsOf:)` が失敗しないように、ダミー音声ファイルの確保や存在チェック後のフォールバック処理を追加する。
- [x] `savePodcastsToStorage` でバンドル内ファイルの絶対パスを保存しており、アプリ更新やテスト起動でパスが無効化された際に再構築されない問題を解消する（ファイル存在確認と再読込ロジックの導入など）。
- [x] ライブラリ画面のシート表示で `@State private var selectedPodcast` にコピーされた値が更新されず UI が古いままになるので、`PodcastPlayerViewModel` 内の単一データソースを参照するようリファクタリングする。
- [x] `AsaPodcastPlayerApp` で `.preferredColorScheme(.light)` を強制しておりユーザーの外観設定を無視するため、必要に応じてユーザー設定に委ねるか設定項目を設ける。
