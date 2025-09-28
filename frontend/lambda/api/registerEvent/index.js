const { SQS_URL } = process.env;

exports.handler = async (event) => {
  // Aquí guardarías en RDS; por ahora devolvemos ok
  return { statusCode: 201, body: JSON.stringify({ ok: true, msg: "registered" }) };
};
