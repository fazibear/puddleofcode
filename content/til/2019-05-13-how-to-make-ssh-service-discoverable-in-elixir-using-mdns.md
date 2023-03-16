---
section: til
date: 2019-05-13
slug: how-to-make-ssh-service-discoverable-in-elixir-using-mdns
title: How to Make SSH Service Discoverable in Elixir Using mDNS?
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---
To make service discoverable we need following services registered:

```elixir
[
  # create domain for an ip
  %Mdns.Server.Service{domain: "somedomain.local", data: :ip, ttl: 450, type: :a},

  # make service discoverable
  %Mdns.Server.Service{domain: "_services._dns-sd._udp.local",data: "_ssh._tcp.local",ttl: 4500, type: :ptr},

  # register ssh service
  %Mdns.Server.Service{domain: "_ssh._tcp.local",data: "SOME NAME._ssh._tcp.local",ttl: 4500, type: :ptr},

  # point service to our domain and port (22)
  %Mdns.Server.Service{domain: "SOME NAME._ssh._tcp.local",data: {0,0,22, 'somedomain.local'},ttl: 4500,type: :srv},

  # empty txt service (some tools expext that)
  %Mdns.Server.Service{domain: "SOME NAME._ssh._tcp.local",data: [],ttl: 4500,type: :txt})
] |> Enum.each(&Mdns.Server.add_service/1)
```
