' comment

a = "string"
b = 99
c = true
d = [a: 1, b: "hello world!"]

a = [a: 1, b: "string", c: false]
print(a.a)		' 1
print(a["b"])	' "string"

b = ["x": 99, "y": true]
print(b.x)		' 99

c = [1, 99, 32]
print(c[1])		' 1

while [condition]:
	' do something

for i = 0, 10, 2:
	' ...
	
if [condition]:
	' do something
elseif [condition]:
	' do another thing
else:
	' final thing