import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import "./index.css";
import Layout from "./Layout";
import WriteBox from "./WriteBox";
import Empty from "./Empty";
import reportWebVitals from "./reportWebVitals";
import { GoogleOAuthProvider } from '@react-oauth/google';


const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <>
      <GoogleOAuthProvider clientId = "283938763304-jpdersinntpv2bua49u7ot6h4pkp30o6.apps.googleusercontent.com">
    <BrowserRouter>
       <Routes>
         <Route element={<Layout />}>
           <Route path="/" element={<Empty />} />
           <Route path="/notes" element={<Empty />} />
           <Route
             path="/notes/:noteId/edit"
             element={<WriteBox edit={true} />}
           />
           <Route path="/notes/:noteId" element={<WriteBox edit={false} />} />
           {/* any other path */}
           <Route path="*" element={<Empty />} />
         </Route>
       </Routes>
     </BrowserRouter>
     </GoogleOAuthProvider>

  </>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();