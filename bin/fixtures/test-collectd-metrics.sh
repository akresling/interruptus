curl -X POST -H "Content-Type:application/json" -d @- http://localhost:8080/api/type <<EOF | python -m json.tool
{
  "name":"CollectdMetric",
  "properties":{
    "plugin":"string",
    "plugin_instance":"string",
    "type":"string",
    "type_instance":"string",
    "datacenter":"string",
    "time":"long",
    "value":"double",
    "name":"string",
    "host":"string"
  }
}
EOF

# {"type":"CollectdMetric","body":{"plugin":"disk","plugin_instance":"disk_sdd1","datacenter":"east_coast","time":"1399577466","host":"mq01.ss","name":"usage","value":"1234591"}}

curl -X POST -H "Content-Type:application/json" -d @- http://localhost:8080/api/statement <<EOF | python -m json.tool
{"name": "eventlogdebug", "query":"SELECT * FROM CollectdMetric WHERE host = 'mq01.ss'", "debug": true, "started": true}
EOF

curl -X POST -H "Content-Type:application/json" -d @- http://localhost:8080/api/flow <<EOF | python -m json.tool
{"name": "EventsOut", "started": true, "masterOnly":true, "query":"create dataflow EventsOut EventBusSource -> outstream<CollectdMetric> {} AMQPSink(outstream) { host: 'localhost', exchange: 'alerts', queueName: 'alerts', username: 'guest', password: 'guest', routingKey: '#', declareAutoDelete: false, declareDurable: true, collector: {class: 'org.cad.interruptus.EventToAMQP'},logMessages: true}"}
EOF

curl -X POST -H "Content-Type:application/json" -d @- http://localhost:8080/api/flow <<EOF | python -m json.tool
{"name": "EventsIn", "started": true, "query":"create dataflow EventsIn AMQPSource -> EventsIn<CollectdMetric> {  host: 'localhost',  exchange: 'collectd_metrics', port: 5672, username: 'guest',  password: 'guest',  routingKey: '#', collector: {class: 'org.cad.interruptus.AMQPJsonToMap'}, logMessages: true  } EventBusSink(EventsIn){}"}
EOF

# curl -X POST http://localhost:8080/api/flow/EventsIn/start | python -m json.tool
# curl -X POST http://localhost:8080/api/flow/EventsOut/start | python -m json.tool
# curl -X POST http://localhost:8080/api/statement/eventlogdebug/start | python -m json.tool


curl -X GET http://localhost:8080/api/flow/EventsIn/state | python -m json.tool
curl -X GET http://localhost:8080/api/flow/EventsOut/state | python -m json.tool
curl -X GET http://localhost:8080/api/statement/eventlogdebug/state | python -m json.tool