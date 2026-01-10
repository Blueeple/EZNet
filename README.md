
# EZNet Beta V1 - Independent

🚀EZNet a DOP based Roblox networking module.

🐛This is a Beta bugs are to be expected.

🛠️More EZNet API is to be added.



## Features

- Buffer based serialization
- Modular signal handlers
- Unreliable remote event support
- Easy to use bindings


## FAQ

#### Will EZNet get a better installation process? Eg: [Wally](https://wally.run)

Yes, but may reqiure the use of 2 wally install parameters, and Potentially a Plugin installer. 👀

#### Will EZNet get better optimization

Yes, I'm aware of some performance issues and those will be fixed overtime.

#### Does EZNet support Remote functions?

No, I'll think about adding it.

## API Reference

#### Creating a packet

```http
  EZnetServer.CreatePacket("Name", true, "Reliable", { "Boolean" })
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