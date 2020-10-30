function transform(line) {
var values = line.split(',');

var obj = new Object();
//obj.location = values[0];
//obj.name = values[1];
//obj.age = values[2];
//obj.color = values[3];
//obj.coffee = values[4];
obj.qtr = values[0];
obj.property_type = values[1];
obj.median_price = values[2];
obj.sales = values[3];
obj.suburb = values[4];
obj.postcode = values[5];
obj.state = values[6];
var jsonString = JSON.stringify(obj);

return jsonString;
}