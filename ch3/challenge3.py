#Challenge #3
#We have a nested object. We would like a function where you pass in the object and a key and get back the value.
import json
ajson=input("object = ")
bjson=json.loads(ajson)
dstring=input("key = ")
ts=bjson
for element in dstring.split('/'):
    ts=ts[element]
print("value = "+ts)