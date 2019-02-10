http://khigashigashi.hatenablog.com/entry/2018/09/25/232313 の写経

※ セキュリティグループのアウトバウンドルール egress は、GUIで設定するとデフォルトで「すべて許可」になるが、Terraform だとデフォルト設定がないため、別途設定する必要がある

```
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

https://www.terraform.io/docs/providers/aws/r/security_group.html