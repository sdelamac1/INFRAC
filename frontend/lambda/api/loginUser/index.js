exports.handler = async (event) => {
  return { statusCode: 200, body: JSON.stringify({ ok: true, message: "login stub" }) };
};
