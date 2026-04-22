
# EZNet V1.1b - Independent

🚀EZNet a DOP based Roblox networking module.

🐛This is a Beta bugs are to be expected.

🛠️More EZNet API is to be added.



## Features

- Buffer based serialization
- Modular signal handlers
- Unreliable remote event support
- Easy to use bindings


## FAQ

#### Why does EZNet behave's funky at times?

EZNet was built in a way were you must define remotes and call `EZNet.GetPacket("Packet")` after initialization, but I'm working on addding proper **Async** functions.

#### Will EZNet get better optimizations (Eg: Native event connections, instead of goodSignal)

Yes, these changes will come over time.

#### Does EZNet support Remote functions?

Yes, these are plannd but they would most likely be emulated using remote events.

#### Will EZNet get a automatic RBXType to Buffer system like blink?
Yes, but not at this time we have bigger fish to fry.

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