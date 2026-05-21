function handler(event) {
  var weight = 10; // percentage to green
  var rand = Math.random() * 100;
  if (rand < weight) {
    var request = event.request;
    request.origin = { s3: { domainName: 'deploy-lab-green.s3.amazonaws.com' }};
    return request;
  }
  return event.request;
}
