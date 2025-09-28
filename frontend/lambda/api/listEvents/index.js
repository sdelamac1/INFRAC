exports.handler = async () => {
  return { statusCode: 200, body: JSON.stringify([{ id: 1, title: "Evento demo" }]) };
};
