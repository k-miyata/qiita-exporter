# Qiita Exporter

A Ruby script to export Qiita posts.

## Features

- QiitaやQiita Teamの投稿をダウンロードします。
- 投稿に紐づくコメントや本文中の画像もダウンロードします。
- 同梱の`QiitaExporter::DataStore`を使って、ダウンロードしたデータをRubyオブジェクトとして簡単に扱うことができます。

## Requirements

- Ruby 2.6+
- [Bundler](https://bundler.io/)

## Usage

最初に、Qiita Exporterの動作に必要なgemをインストールしてください。

```sh
bundle install --path vendor/bundle
```

その後、`main.rb`を実行してください。

```sh
bundle exec ruby main.rb
Type your Qiita Team ID: # 1
Type your Qiita username: # 2
Type your access token with read access: # 3
```

1. Qiita TeamのチームIDを入力します。Qiita TeamではなくQiitaの投稿をダウンロードする場合は何も入力しません。
2. ダウンロードしたい投稿のユーザIDを入力します。全ての投稿をダウンロードする場合は何も入力しません。
3. [アクセストークン](https://qiita.com/settings/applications)を入力します。Qiitaの投稿をダウンロードする場合は`read_qiita`、Qiita Teamの場合は`read_qiita_team`のスコープが必要です。

## License

See [LICENSE](LICENSE).
