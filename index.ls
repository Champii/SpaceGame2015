require! {
  nodulator: N
  \nodulator-account : Account
  \./server : Server
}

N.Use Account

Server.Init!
