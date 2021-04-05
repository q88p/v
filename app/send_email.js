var args = process.argv.slice(2);

if (!args[0] || !args[1] || !args[2]) {
  console.log("usage: node configuration_set_name sender@example.com destination@example.com")
  return;
}

// Load the AWS SDK for Node.js
var AWS = require('aws-sdk');
// Set the region
AWS.config.update({region: 'eu-north-1'});

// Create sendEmail params
var params = {
  ConfigurationSetName: args[0],
  Destination: {
    ToAddresses: [
      args[2]
    ]
  },
  Message: {
    Body: {
      Html: {
       Charset: "UTF-8",
       Data: "HTML_FORMAT_BODY"
      },
      Text: {
       Charset: "UTF-8",
       Data: "TEXT_FORMAT_BODY"
      }
     },
     Subject: {
      Charset: 'UTF-8',
      Data: 'Test email'
     }
    },
  Source: args[1],
  ReplyToAddresses: [
     args[1]
  ],
};

// Create the promise and SES service object
var sendPromise = new AWS.SES({apiVersion: '2010-12-01'}).sendEmail(params).promise();

// Handle promise's fulfilled/rejected states
sendPromise.then(
  function(data) {
    console.log(data.MessageId);
  }).catch(
    function(err) {
    console.error(err, err.stack);
  });
