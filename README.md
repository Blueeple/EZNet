
# EZNet V1

🚀EZNet another Roblox oop based networking module.

🐛This is a Beta bugs are to be expected.

🛠️More EZNet API is to be added.



## Features

- Buffer based serialization
- Modular signal handlers
- Unreliable remote event support
- Easy to use bindings


## FAQ

#### Will EZNet get a better installation process? Eg: [Wally](https://wally.run)

Yes, but not at this time.

#### Will EZNet get better optimization

Yes, but only from your feedback

#### Does EZNet support Remote functions?

No, It might never get added.

#### Why does the `:BlockPlayer()` and `:UnBlockPlayer()` functions not work?

I didn't finish them but I just wanted something to publish to github.
## API Reference

#### Creating a packet

```http
  EZnetServer:CreatePacket("Packet", true, "Reliable", { "Boolean" })
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `Name`      | `string` | **Required**. Name of Packet to fetch. |
| `Enabled`      | `boolean` | **Required**. Decides if the packet can be used. |
| `Replicator`      | `string` | **Required**. Which remote should the packet use. |
| `TypesList`      | `table` | **Required**. What Types should the packet allow. |

#### Getting packets

```http
  EZNet.GetPacket("Packet")
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `Name`      | `string` | **Required**. Name of Packet to fetch |



## Feedback

If you have any feedback, please reach out to me on my [Discord](https://discordapp.com/users/blueeple)


## Authors

- [@Blueeple](https://www.github.com/blueeple)