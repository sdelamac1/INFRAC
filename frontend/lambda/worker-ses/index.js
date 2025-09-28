exports.handler = async (event) => {
  console.log("SQS batch:", JSON.stringify(event.Records?.length || 0));
  // Aquí llamarías a SES con AWS SDK v3; por ahora solo log
  return {};
};
